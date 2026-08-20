# ACPI PEP/ACDC 错误分析与修复建议

## 结论

BIOS 的 `SSDT25`（OEM table ID `UPEP`）引用了不存在的命名空间路径：

```text
\\_SB.ACDC.RTAC
\\_SB.ACDC.MONR
\\_SB.ACDC.YARR
```

实际 DSDT 中定义的是 `\\_SB.AC0.ACDC`，并且反编译得到的全部 DSDT/SSDT 中都没有
`RTAC`、`MONR`、`YARR` 这三个对象。

内核日志中的：

```text
ACPI BIOS Error (bug): Could not resolve symbol [\\_SB.ACDC.RTAC], AE_NOT_FOUND
ACPI Error: Aborting method \\_SB.PEP._DSM due to previous error (AE_NOT_FOUND)
```

不是电池 SSDT 补丁造成的，而是固件表自身的不一致。

## “代码被跳过”的范围

ACPI 方法遇到 `AE_NOT_FOUND` 后，本次方法调用会中止，后面的 AML 语句不会执行。
在 `SSDT25.dsl` 中，错误引用位于 `PEP._DSM` 的 `Arg2 == 4` 分支：

1. 读取并清除 `EC0.S0E1`；
2. 读取 `ACDC.RTAC`；
3. 根据结果写入 `EC0.EYER` 和 `EC0.EMON`；
4. 继续执行 EC 电源状态切换和锁操作。

因此，进入这个分支时，步骤 3 之后的电源管理代码会被跳过。其他 `PEP._DSM` 分支、普通
ACPI `_PSR`、设备驱动自己的 suspend/resume 回调不会因此全部失效。

这可以解释部分平台电源状态恢复异常，但目前不能证明它单独导致触控板灵敏度下降。触控板
在 `\\_SB.I2CB.TPAD` 下，由 `i2c_hid_acpi` 驱动；现有日志显示重载该驱动会重新初始化控制器，
所以触控板问题仍更像是 `s2idle` 唤醒后的 I2C-HID 状态未恢复。

## 已完成的静态验证

构造了一个最小 SSDT，为 `\\_SB.ACDC` 增加 `RTAC`、`MONR`、`YARR` 三个整数对象。该 AML
大小为 82 字节，并已使用 `acpiexec` 与原始 DSDT/SSDT25 一起加载；命名空间加载不再报错。

这只证明命名空间错误可以被补齐，尚未证明真实机器上的睡眠/唤醒行为改善。

## 建议的修复顺序

### 1. 暂不加入 I2C-HID 重载脚本

排查阶段已从安装包移除 I2C-HID 重载脚本，避免它掩盖真实的 suspend/resume 问题。此前脚本中的命令
存在以下错误：

```text
i2c_hid_acpi: unknown parameter 'i2c_hid' ignored
```

如果后续确认必须恢复驱动，命令应只执行：

```sh
modprobe i2c_hid_acpi
```

`i2c_hid` 会作为依赖自动加载。

### 2. 再进行 ACPI shim 的 A/B 测试

可将最小 SSDT 作为独立的 `acpi_override` 表测试。每次测试后检查：

```sh
journalctl -b -k | grep -E 'ACDC|PEP|AE_NOT_FOUND'
journalctl -b -k | grep -E 'UNIW0001|i2c_hid'
```

客观收益应同时满足：

- 唤醒后不再出现 `ACDC.RTAC`/`PEP._DSM` 错误；
- `ucsi_acpi` 超时或其他电源恢复错误没有增加；
- 触控板无需重载模块即可保持相同灵敏度。

如果只满足第一项，说明 shim 仅修复了日志和一条 PEP 路径，不能宣称解决触控板问题。

## 风险与限制

`RTAC`、`MONR`、`YARR` 的固件语义无法从当前表中恢复。补零是为了避免方法中止，并不一定
等价于厂商原本的值；它可能改变 EC 的显示器/电源状态处理。因此不建议在没有 A/B 睡眠测试
前把 shim 永久写入 initramfs。若测试无收益，应撤回 shim，只保留正确的 I2C-HID 重载方案。

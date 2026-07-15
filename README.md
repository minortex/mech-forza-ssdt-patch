# Mechrevo Wujie 14x ACPI SSDT Patch

本仓库保存机械革命无界 14x / Forza 系列 AMD 平台的本机 ACPI 表备份，以及用于补充电池信息上报的 SSDT override。

当前补丁解决两类固件未标准暴露的数据：

- 电池循环次数：给 `\_SB.BAT0` 补充 `_BIX`，从 EC `0x04A6..0x04A7` 读取 cycle count。
- 电池温度：新增 `\_TZ.BATZ` thermal zone，从 EC `0x04A2..0x04A3` 读取 0.1 K 单位的温度。

这些 SSDT 依赖本机固件中的 `\_SB.BAT0`、`\_SB.INOU.ECRR` 和 EC 命名空间，只适用于同一套 ACPI 表或高度相近的机型。移植到其他机器前需要先核对 DSDT/SSDT 命名空间和 EC 寄存器定义。

## 目录结构

- `origin_dsl/`：从机器固件导出的原始 DSDT/SSDT ASL 反编译结果，用于追溯命名空间和方法实现。
- `dsl/`：手写 SSDT override 源码。
- `grub/`：用于在启动时加载 AML 的 GRUB 片段。
- `docs/`：EC 寄存器和逆向结论说明。
- `aml/`、`hex/`：本地构建输出目录，内容由 `make` 生成，不纳入 Git。

## SSDT 表

`ssdt-bix.dsl` 在 `\_SB.BAT0` 下补充 `_BIX`。固件已有 `_BIF`，但 `_BIF` 不包含 cycle count；该表复用固件 `\_SB.INOU.ECRR` 方法读取 EC `0x04A6` 和 `0x04A7`，按 unsigned little-endian 合成为 `_BIX` 第 9 项。

`ssdt-battery-temp.dsl` 在 `\_TZ` 下新增 `BATZ` 热区。`_TMP` 读取 EC `0x04A2..0x04A3` 并直接返回，单位与 ACPI `_TMP` 要求的 0.1 K 一致；`_TZD` 将热区关联到 `\_SB.BAT0`。

## 构建

需要安装 `iasl`。在仓库根目录执行：

```sh
make
```

构建会把 `dsl/*.dsl` 编译到 `aml/*.aml`，并刷新对应的 `hex/*.hex` 调试输出。生成产物已通过 `.gitignore` 排除。

清理输出：

```sh
make clean
```

## 部署

1. 编译后把 `aml/ssdt-bix.aml` 和 `aml/ssdt-battery-temp.aml` 复制到 `/boot/acpi/`。
2. 把 `grub/01_acpi_bix` 安装为 `/etc/grub.d/01_acpi_bix`，并保留可执行权限。
3. 根据系统实际的 `/boot` 路径检查脚本里的 `acpi /@/boot/acpi/...`。该路径适用于 `/` 位于 Btrfs `@` 子卷的布局；其他布局需要相应调整。
4. 重新生成 GRUB 配置并重启。

## 验证

重启后可以通过 Linux 的 ACPI 电池和热区接口检查结果：

```sh
cat /sys/class/power_supply/BAT0/cycle_count
cat /sys/class/thermal/thermal_zone*/type
cat /sys/class/thermal/thermal_zone*/temp
```

若系统没有加载 override，先检查 GRUB 最终配置中是否包含两条 `acpi` 命令，再检查内核日志中的 ACPI table override 记录。

## 说明

EC 寄存器定义和字段来源见 `docs/ec-register-map.md`。这里的 cycle count 是 EC/电池燃料计维护的原始累计值；目前只确认了寄存器位置、字节序和系统管理器的展示方式，不能据此推断 EC 固件内部的递增规则。

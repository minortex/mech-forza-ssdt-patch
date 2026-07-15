/*
 * Add ACPI _BIX (Battery Information Extended) to the firmware BAT0 device.
 *
 * The firmware DSDT has _BIF but no _BIX.  Its EC cycle counter is a 16-bit
 * little-endian value at offsets 0x04A6 and 0x04A7 (EC registers 1190/1191).
 * Read it through the existing INOU.ECRR method so the SSDT uses the same
 * serialized MMIO access path as the firmware and the Linux EC tools.
 */

DefinitionBlock ("", "SSDT", 2, "MFC", "BIXFIX", 0x00000001)
{
    External (\_SB.BAT0, DeviceObj)
    External (\_SB.INOU.ECRR, MethodObj)    // 1 Argument
    External (\_SB.PCI0.SBRG.EC0.XIF1, IntObj)
    External (\_SB.PCI0.SBRG.EC0.XIF2, IntObj)
    External (\_SB.PCI0.SBRG.EC0.XIF3, IntObj)
    External (\_SB.PCI0.SBRG.EC0.XIF4, IntObj)
    External (\_SB.PCI0.SBRG.EC0.XIF7, IntObj)
    External (\_SB.PCI0.SBRG.EC0.ISDB, IntObj)
    External (\_SB.PCI0.SBRG.EC0.CYCN, IntObj)

    Scope (\_SB.BAT0)
    {
        Method (_BIX, 0, Serialized)
        {
            Name (BIX0, Package (0x14)
            {
                Zero,       // Revision
                One,        // Power unit: mAh
                0x0C56,     // Design capacity
                0x0C56,     // Last full charge capacity
                Zero,       // Battery technology: rechargeable
                0x2A30,     // Design voltage (mV)
                Zero,       // Design capacity warning
                Zero,       // Design capacity low
                Zero,       // Cycle count, filled below
                Zero,       // Measurement accuracy
                Zero,       // Maximum sampling time
                Zero,       // Minimum sampling time
                Zero,       // Maximum averaging interval
                Zero,       // Minimum averaging interval
                0x10,       // Battery capacity granularity 1
                0x08,       // Battery capacity granularity 2
                "standard", // Model number
                "00001",    // Serial number
                "LiON",     // Battery type
                "OEM"       // OEM information
            })
            Name (LOWB, Zero)
            Name (HIGH, Zero)

            /* Keep _BIX capacity fields consistent with the firmware _BIF. */
            BIX0 [0x02] = \_SB.PCI0.SBRG.EC0.XIF1
            If (\_SB.PCI0.SBRG.EC0.ISDB == One)
            {
                If (\_SB.PCI0.SBRG.EC0.CYCN >= 0x32)
                {
                    BIX0 [0x03] = \_SB.PCI0.SBRG.EC0.XIF2
                }
                Else
                {
                    BIX0 [0x03] = \_SB.PCI0.SBRG.EC0.XIF1
                }
            }
            Else
            {
                BIX0 [0x03] = \_SB.PCI0.SBRG.EC0.XIF2
            }

            BIX0 [0x04] = \_SB.PCI0.SBRG.EC0.XIF3
            BIX0 [0x05] = \_SB.PCI0.SBRG.EC0.XIF4
            BIX0 [0x0E] = \_SB.PCI0.SBRG.EC0.XIF7

            /* EC[1190..1191] = EC[0x04A6..0x04A7], unsigned LE. */
            LOWB = \_SB.INOU.ECRR (0x04A6)
            HIGH = \_SB.INOU.ECRR (0x04A7)
            HIGH <<= 8
            LOWB |= HIGH
            BIX0 [0x08] = LOWB

            Return (BIX0)
        }
    }
}

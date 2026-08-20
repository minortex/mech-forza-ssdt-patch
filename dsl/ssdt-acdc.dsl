/* Define the namespace expected by the firmware UPEP SSDT. */

DefinitionBlock ("", "SSDT", 2, "MFC", "ACDCFIX", 0x00000001)
{
    Scope (\_SB)
    {
        Device (ACDC)
        {
            Name (_HID, "MFC0001")
            Name (RTAC, Zero)
            Name (MONR, Zero)
            Name (YARR, Zero)
        }
    }
}

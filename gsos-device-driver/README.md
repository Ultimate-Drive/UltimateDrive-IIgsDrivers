## UltimateDrive Apple IIgs GSOS Device Driver


## Notes about GSOS Device Drivers
There are two types of device drivers
- Loaded Driver: Loaded into memory at system startup or during execution
- Generated Driver: created by GS/OS to provide a compatible interface to slot-based fìrmware I/O drivers

All GS/OS generated drivers support these standard device calls:
- DInfo
- DStatus
- DControl
- DRead
- DWrite
- DRename
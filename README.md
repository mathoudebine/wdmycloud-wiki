# WD MyCloud Tips & Tricks
This page acts as a wiki for administartor commands and tools used with the MyCloud NAS sold by WD. The following page applies to the original MyCloud products, NOT the new "MyCloud Home" series.

## Disclaimer
DO AT YOUR OWN RISK !  
None of the authors, contributors, administrators, vandals, or anyone else connected with this page, in any way whatsoever, can be responsible for your use of the information contained in or linked from these web pages.

## Pre-requisites
To use the commands listed below, you need to have SSH support activated for your drive.  
To do this follow this link : https://support.wdc.com/knowledgebase/answer.aspx?ID=10495  
You can now connect to your MyCloud SSH server using tools like Putty. The default username & password are one the link above.

## Useful commands
### Drive SMART state
The MyCloud does not offer a lot of information on the drive state on its web interface : you only have access to a diagnosis status that states "OK", same for the temparture. To get more information from the drive, the tool `smartctl` is available on the MyCloud OS.
> NOTE : All the following commands are for a single-bay MyCloud. Adapt to use with more than one disk.

To get all information from the disk SMART system :
```bash
/usr/sbin/smartctl /dev/sda -a
```

### Temperature
To get the temparture of the disk in °C (this is a command for the single-bay MyCloud. Adapt to use with more than one disk)
```bash
/usr/sbin/smartctl /dev/sda -a | /bin/grep Temperature_Celsius | /usr/bin/awk '{print $10}'
```

#### Self-tests
The hardware self tests built in hard disks are the perfect solution to test the hard disk status quickly or with very high detail. Usually the short and extended self tests are supported by the hard disks but some models support other (conveyance) self test also. **The self tests are non-destructive, they do not affect the data stored on the hard disk**. During the test, the hard disk is still usable but may be slower. It is recommended not to use the hard drive actively while running a self test.

The list of all supported self tests and the estimated time of such tests are displayed by the `/usr/sbin/smartctl /dev/sda -a` command.  By default, the MyCloud system does not run these tests periodically, and rely only on SMART pre-fail attributes to detect a disk failure. It can be a good idea to run these tests periodically, by a `cron` programmation or at least manually.

* The _Short self test_ verifies the major components of the hard disk (read/write heads, servo, electronics, internal memory, etc). This test takes only some minutes.
```bash
/usr/sbin/smartctl /dev/sda --test=short
```

* The Extended self test performs the above and it has a complete surface scan which reveals the problematic areas (if any) and forces the bad sector reallocation. It is recommended to periodically use this test to verify the disk health - especially on a hard disk with less than 100% health. **NOTE : this test takes several hours !**
```bash
/usr/sbin/smartctl /dev/sda --test=long
```

* The Conveyance self test performs manufacturer-specific test steps. This usually verifies the mechanical parts of the hard disk to ensure that no handling damage occured. This test does not need to be run periodically, only after moving the NAS from one location to another.
```bash
/usr/sbin/smartctl /dev/sda --test=conveyance
```

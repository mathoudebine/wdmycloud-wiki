# WD MyCloud Tips & Tricks
![](http://mycloud.com/images/mycloudos3_desktop.png)  
This page acts as a wiki for administartor commands and tools used with the MyCloud NAS sold by WD. The following page applies to the original MyCloud products, NOT the new "MyCloud Home" series.

## Disclaimer
DO AT YOUR OWN RISK !  
Be very careful as you can brick your NAS firmware, and even damage the hardware by doing things wrong.  
None of the authors, contributors, administrators, or anyone else connected with this page, in any way whatsoever, can be responsible for your use of the information contained in or linked from this web page.

## Pre-requisites
To use the commands listed below, you need to have SSH support activated for your drive.  
To do this follow this link : https://support.wdc.com/knowledgebase/answer.aspx?ID=10495  
You can now connect to your MyCloud SSH server using tools like Putty. The default username & password are one the link above.

## Drive SMART state
The MyCloud does not offer a lot of information on the drive state on its web interface : you only have access to a diagnosis status that states "OK", same for the temparture. To get more information from the drive, the tool `smartctl` is available on the MyCloud OS.
> NOTE : All the following commands are for a single-bay MyCloud. Adapt to use with more than one disk.

To get all information from the disk SMART system printed in the console output :
```bash
/usr/sbin/smartctl /dev/sda -a
```

To be added in a script, this command can be completed by the `-q`option :
```bash
/usr/sbin/smartctl -q silent -a /dev/sda; echo $?
```
This command examines silently all SMART data for device /dev/sda, but produce no printed output. The exit status (the $? shell variable) is `1` if :
* Attributes are out of bound (see `/usr/sbin/smartctl /dev/sda -A` for details)
* SMART status is failing (see `/usr/sbin/smartctl /dev/sda -H` for details)
* there are errors recorded in the self-test log (see `/usr/sbin/smartctl /dev/sda --log=selftest` for details)
* there are errors recorded in the disk error log (see `/usr/sbin/smartctl /dev/sda --log=error` for details)  

If everything is fine, the exit status is `0`.

### Health status
Prints the health status of the device or pending TapeAlert messages.  
If the device reports failing health status, this means either that the device has already failed, or that it is predicting its own failure within the next 24 hours. If this happens, use the `/usr/sbin/smartctl /dev/sda -a` command to get more information, and **get your data off the disk and to someplace safe as soon as you can**. 
```bash
/usr/sbin/smartctl /dev/sda -H
```

### Error log
Prints the Summary SMART error log. SMART disks maintain a log of the most recent five non-trivial errors. There should be no errors in an operational state. If any, it is advised to run a self-test to check drive integrity.
```bash
/usr/sbin/smartctl /dev/sda --log=error
```

### Temperature
To get the temparture of the disk in °C
```bash
/usr/sbin/smartctl /dev/sda -A | /bin/grep Temperature_Celsius | /usr/bin/awk '{print $10}'
```
> NOTE : The recommended temperature range from Western Digital for the drive of the MyCloud Single-bay unit drive (WD30EFRX-68EUZN0) is between 0 and 65 °C.

### Self-tests
The hardware self tests built in hard disks are the perfect solution to test the hard disk status quickly or with very high detail. Usually the short and extended self tests are supported by the hard disks but some models support other (conveyance) self test also. **The self tests are non-destructive, they do not affect the data stored on the hard disk**. During the test, the hard disk is still usable but may be slower. It is recommended not to use the hard drive actively while running a self test.

The list of all supported self tests and the estimated time of such tests are displayed by the `/usr/sbin/smartctl /dev/sda -c` command. By default, the MyCloud system does not run these tests periodically. It can be a good idea to run these tests periodically, by a `cron` programmation or at least manually.

* The _Offline test_ is not really a self-test test but rather a "data collection" process. This test is immediate, it produces no output but only updates the SMART Attribute values displayed by the `/usr/sbin/smartctl /dev/sda -A` command. It can be run automatically by the disk itself (see below).
```bash
/usr/sbin/smartctl /dev/sda --test=offline
```

* The _Short self test_ verifies the major components of the hard disk (read/write heads, servo, electronics, internal memory, etc). This test takes only some minutes.
```bash
/usr/sbin/smartctl /dev/sda --test=short
```

* The _Extended self test_ performs the above and it has a complete surface scan which reveals the problematic areas (if any) and forces the bad sector reallocation. It is recommended to periodically use this test to verify the disk health - especially on a hard disk with less than 100% health. **NOTE : this test takes several hours !** To follow the progression of this test you can use the `/usr/sbin/smartctl /dev/sda -l selftest` command.
```bash
/usr/sbin/smartctl /dev/sda --test=long
```

* The _Conveyance self test_ performs manufacturer-specific test steps. This usually verifies the mechanical parts of the hard disk to ensure that no handling damage occured. This test does not need to be run periodically, only after moving the NAS from one location to another.
```bash
/usr/sbin/smartctl /dev/sda --test=conveyance
```

To display the result of the tests, run the following command once the test is finished (offline tests are not displayed) :
```bash
/usr/sbin/smartctl /dev/sda --log=selftest
```
The tests results are displayed on a table, sorted by execution date :
```
SMART Self-test log structure revision number 1
Num  Test_Description    Status                  Remaining  LifeTime(hours)  LBA_of_first_error
# 1  Short offline       Completed without error       00%     34291         -
# 2  Short offline       Completed without error       00%     25869         -
# 3  Short offline       Completed without error       00%         0         -
```
> If the `LBA_of_first_error` column is empty, it means that the test ran without errors.  
> If a line indicates `# 6  Extended offline    Self-test routine in progress 90%` (only for extended self-test) it means that the test is still running, check back later.  
> If the test you just stared is not displayed (for short/conveyance self-test) it means that the test is still running, check back later.

The SMART attributes have also been updated when the test ends : 
```bash
/usr/sbin/smartctl /dev/sda -A
```

If errors hapenned during tests, the error log can be displayed by :
```bash
/usr/sbin/smartctl /dev/sda --log=error
```

### Enable automatic self-tests & data collection
This command enables SMART automatic offline test, which scans the drive every four hours for disk defects.
```bash
/usr/sbin/smartctl --smart=on --offlineauto=on --saveauto=on /dev/sda 
```
The results of these automatic or immediate offline testings (data collection) will be reflected in the values of the SMART Attributes displayed by `/usr/sbin/smartctl /dev/sda -A`, errors will be logged in `/usr/sbin/smartctl /dev/sda --log=error`.
 
## Front panel LED
The front panel LED is driven by the system using a standard led driver : the driver exposes the LED capabilities from userspace through file descriptor in the `/sys/class/leds/system_led/` folder.  

**NOTE : once again, I advise you to be very careful while editing hardware-related driver states.** We don't know if the driver used by WD fully matches with hardware capabilities and/or authorized values range. For example, do not try to change the LED brightness as the SSH connection would crash.  

All the modifications made will be overwriten sometimes by the WD software and services that manage the NAS. If you want the modifications to persist, you have to put them in a script and apply them regularly e.g. with `cron`

To change the LED color (basic colors are allowed : black, green, blue, red, orange, yellow, white ...) :
```bash
echo red > /sys/class/leds/system_led/color
```

To make the led blink ('blink') / static ('on'):
```bash
echo blink > /sys/class/leds/system_led/blink
echo on > /sys/class/leds/system_led/blink
```

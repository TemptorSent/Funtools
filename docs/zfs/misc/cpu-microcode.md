# Microcode Updates
##### It may be desirable to load the latest cpu microcode updates from the manufacturers to protect against various vulnerabilities. Microcode updates should be loaded at boot time on every boot.

#### To load microcode updates via dracut, first install linux-firmware and if using intel, also intel-microcode.

emerge -av linux-firmware intel-microcode

#### Regenerate your initramfs using Dracut however your usual method may be, but add the switch "--early-microcode" to ensure the necessary microcode is actually included in your initramfs to be loaded at boot time. This will be necessary every time you create a new initramfs.

dracut --early-microcode

##### Tip: One could also create /etc/dracut.conf.d/microcode.conf with the following and simply run it by typing "dracut":

early_microcode="yes"

# zksoftware_attend_helper
according to the https://github.com/buildroot/buildroot 's information, we can crosscompie the binary of necessary tool for dedicate mipsel platform that the zksoftware attend machine used, e.g. jq awk sqllite, after that when we get the root password from internet we can estabish the ftp connection by busybox that natively build. then we can create a cron job by busybox to let the machine performing the attend action exclude the holiday routinely.
#Component explanation
login.sh: main script to perform the attend action in mipsel platform
tap.sh: a qemu script that can create a mipsel emulation machine ,and also open up a network interface that can let us to verify the availability for the script.
ZKDB.db: a sample db store the information of attendant.

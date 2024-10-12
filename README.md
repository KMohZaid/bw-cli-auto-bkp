# How to setup auto bitwarden/vaultwarden backup to Rclone Remote in VPS
NOTE: This guide is made from ubuntu vps so username is ubuntu.
> I use Arch, btw.

> Script i made will do daily backup and keep specified older copy (rentention day is limit of copy to keep)
> i also made it to upload latest one with date and 2nd copy with "latest" in end instead of date. This is for 2 reason
> 	1. when every you want to find latest backup, it is easy to find. don't have to check date
> 	2. if my rentention logic is buggy and may delete all dates, we ensure that latest one stays

 NOTE: i will highly recommand you to use **rclone remote**  so you won't loss if vps gone
 TIP : if you use it in android device or locally and your PC(window wsl also got way to have cronjob runs. if setup auto-start). **use rclone localdisk as remote**

WARN : edit code as your liking but keep export format to "encrypted_json". so your data stay safe (specify "--password " in export command if want custom password to encrypt it instead of vault master password)

1.  Install **Bitwarden CLI** using npm `npm install -g @bitwarden/cli`

2. Specify custom host for bitwarden using `bw config server  url`
eg. 
```
bw config server  https://bitwarden.garudalinux.org
```

3. Run `bw login` and login by entering email and password (2FA  code also if you have one, good if you do)

4. Run `bw unlock --raw`, and copy session string. 
> without "--raw" you will get message that vault is unlocked and now you can use it + it will give you code to set env for session and tell how to use in "--session"
> NOTE : Session string is valid for specific time, i don't know how long it is, but do check log file to ensure it is not expired
> you could specify your master password directly in command in script, but it is not good idea to do so.

5. Edit config variable

6. Setup cronjob (specify your path)
```
0 2 * * * /home/ubuntu/bw-cli-auto/bw-export-auto.sh >> /home/ubuntu/bw-cli-auto/bw-export-auto.log 2>&1
```


$source = 'C:\source'
$dest = 'D:\dest'
robocopy $source $dest /MIR /FFT /R:3 /W:10 /Z /NP /NDL

<#
https://superuser.com/a/831868/1826871
/MIR option (equivalent to /E /PURGE) stands for "mirror" and is the most important option. It regards your source folder as the "master", causing robocopy to copy/mirror any changes in the source (new files, deletions etc.) to the target, which is a useful setting for a backup.

/FFT is a very important option, as it allows a 2-second difference when comparing timestamps of files, such that minor clock differences between your computer and your backup device don't matter. This will ensure that only modified files are copied over, even if file modification times are not exactly synchronized.

/R:3 specifies the number of retries, if the connection should fail, and /W:10 specifies a wait time of 10 seconds between retries. These are useful options when doing the backup over a network.

/Z copies files in "restart mode", so partially copied files can be continued after an interruption.

/NP and /NDL suppress some debug output, you can additionally add /NS, /NC, /NFL to further reduce the amount of output (see the documentation for details). However, I would suggest to print some debug output during the first runs, to make sure everything is working as expected.

aditional

/XJD excludes "junction points" for directories, symbolic links that might cause problems like infinite loops during backup. See Brian's comments for details.

/MT[:N] uses multithreading and can speed up transfers of many small files. For N, a value of 2-4 times the number of cores should do on a normal machine. Commented by Zoredache on the original question.
#>
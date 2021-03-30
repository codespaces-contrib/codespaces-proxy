param (
    $remoteUserName='vscode',
    $sshPort='2222',    
    $sshHost='127.0.0.1',
    $localProxyPort='4040',
    $remoteProxyPort='1080'
)

$ErrorActionPreference = "Stop"

# Load IP range config file
$ipRangesToProxy="all"
if (Test-Path -Path "$PSScriptRoot\ips-to-proxy.conf") {
    $ipRangesToProxy = [IO.File]::ReadAllText("$PSScriptRoot\ips-to-proxy.conf").replace("`n", " ")
}

# Delete existing proxy container if it is running
$dockerPsOutput=(docker ps -a -q -f 'name=codespaces-local-proxy-server') -join ''
if ($dockerPsOutput -ne "" ) {
    docker rm --force codespaces-local-proxy-server > $null
}

# Start proxy
Write-Host "Building proxy image..."
Push-Location "$PSScriptRoot\src\proxy"
docker build --build-arg "DANTED_PORT=${localProxyPort}" -t codespaces-local-proxy-server .
Pop-Location
Write-Host "Starting proxy..."
docker run -d --rm --name codespaces-local-proxy-server -p "127.0.0.1:${localProxyPort}:${localProxyPort}" -p "127.0.0.1:${localProxyPort}:${localProxyPort}/udp" codespaces-local-proxy-server

# Load files to send to remote host via SSH
$redsocksConf=[IO.File]::ReadAllText("$PSScriptRoot\src\redsocks.conf")
$proxyConnectScript=[IO.File]::ReadAllText("$PSScriptRoot\src\proxy-connect")
$proxyResetScript=[IO.File]::ReadAllText("$PSScriptRoot\src\proxy-reset")

# Script to run on remote host via SSH
$remoteScript = "
cat << 'SCRIPTEOF' | sudo tee /etc/redsocks.conf.orig > /dev/null
$redsocksConf
SCRIPTEOF
cat << 'SCRIPTEOF' | sudo tee /usr/local/bin/proxy-connect > /dev/null
$proxyConnectScript
SCRIPTEOF
cat << 'SCRIPTEOF' | sudo tee /usr/local/bin/proxy-reset > /dev/null
$proxyResetScript
SCRIPTEOF
clear && sudo proxy-connect 127.0.0.1 $remoteProxyPort $ipRangesToProxy && echo -e '\nPress Ctrl+C to disconnect!' && sleep infinity
"

# Wire up proxy and run script
Write-Host "Wiring up codespace..."
$remoteScript -replace '^r^n', '^n' | ssh -tt -R "127.0.0.1:${remoteProxyPort}:127.0.0.1:${localProxyPort}" -p ${sshPort} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${remoteUserName}@${sshHost} bash -s

# Shut down proxy
Write-Host "`nShutting down local proxy..."
docker stop codespaces-local-proxy-server > $null

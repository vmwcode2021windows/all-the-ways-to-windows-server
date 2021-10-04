# Overview of Cloudbase-init
Cloud-init is a cross-platform system instance initialization software. The name of the package that is used on Windows-based operating systems is known as Cloudbase-init

The software can be used in conjuction with vRealize Automation for initial system configuration during an automated build pipeline.

## Getting started
There are only 2 high level steps to use cloudbase-init with vRA, and they are
* Install and configure the Cloudbase-init package onto your template VM image used by vRA
* Modify vRA Template to include the cloudConfig code for system initialization

## Install the Cloudbase-init package
To prepare a system using vRA and Cloudbase-init, you must prepare a template VM with the Cloudbase-init installation and proper configuration
1. Download the Cloudbase-init installer - [64 bit here](https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi)
1. Install the package silently using
   ```
   msiexec /i CloudbaseInitSetup.msi /qn /l*v log.txt
   ```
3. Modify the Cloudbase-init configuration files. There are a lot of ways this can be done, but documentation on use of the configuration files is sparse. The files [cloudbase-init.conf](cloudbase-init.conf) and [cloudbase-init-unattend.conf](cloudbase-init-unattend.conf) are an example of a way I found that works. The two files provided should overwrite the default files located at C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\

### Analysis of the Cloudbase-init Configuration Files

Let's take a look at one of these files:
```
[DEFAULT]
username=Administrator
groups=Administrators
config_drive_raw_hhd=true
config_drive_cdrom=true
config_drive_vfat=true
bsdtar_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\bsdtar.exe
mtools_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\
verbose=true
debug=true
logdir=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\
logfile=cloudbase-init.log
default_log_levels=comtypes=INFO,suds=INFO,iso8601=WARN,requests=WARN
logging_serial_port_settings=
mtu_use_dhcp_config=true
ntp_use_dhcp_config=true
local_scripts_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\
metadata_services=cloudbaseinit.metadata.services.ovfservice.OvfService
plugins=cloudbaseinit.plugins.common.mtu.MTUPlugin,
        cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin,
        cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin,
        cloudbaseinit.plugins.common.userdata.UserDataPlugin,
        cloudbaseinit.plugins.common.networkconfig.NetworkConfigPlugin,
        cloudbaseinit.plugins.common.localscripts.LocalScriptsPlugin
check_latest_version=true
disable_vmware_customization=true
```
Most of the configuration file is pretty self-explanatory, but the sections to pay attention to are the metadata_services, and plugins areas. 

The metadata_service listed is the OvfService - this is the service that vRA leverages to pass cloudConfig code to the Cloudbase-init package to execute

The listed plugins describe the various services that can be run against the guest OS. There are many plugins available for cloud-init, but not all of them are supported by Cloudbase-init. At the time of this writing, the NetworkConfig plugin is not supported by Cloudbase-init. Any static network addressing on the guest would need to be performed seperately.

disable_vmware_customization=true - I have found in my testing that by changing this to false, an extra and unnecessary reboot is introduced into the build process interrupting the pipeline. YMMV


## Modify the vRA Template to use cloudConfig

The portion of the vRA template that needs to be modified is the properties section of the virtual machine resources. Instead of using a vsphere customization spec for guest customization, you will switch the property to cloudConfig, and then define the code sections you wish to execute. An example of a multi-part cloudConfig would look like this:
```
cloudConfig: |
        Content-Type: multipart/mixed; boundary="===============1598784645116016685=="
        MIME-Version: 1.0

        --===============1598784645116016685==
        Content-Type: text/cloud-config; charset="us-ascii"
        MIME-Version: 1.0
        Content-Transfer-Encoding: 7bit
        Content-Disposition: attachment; filename="cloud-config"

        #cloud-config
        hostname:  ${input.Hostname}

        --===============1598784645116016685==
        Content-Type: text/x-shellscript; charset="us-ascii"
        MIME-Version: 1.0
        Content-Transfer-Encoding: 7bit
        Content-Disposition: attachment; filename="ip-config.ps1"

        #ps1_sysnative
        Get-NetAdapter | New-NetIpAddress -IPAddress ${input.IPAddress} -PrefixLength ${resource.Cloud_vSphere_Machine_1.subnet} -DefaultGateway ${resource.Cloud_vSphere_Machine_1.gateway}

        --===============1598784645116016685==
        Content-Type: text/x-shellscript; charset="us-ascii"
        MIME-Version: 1.0
        Content-Transfer-Encoding: 7bit
        Content-Disposition: attachment; filename="dns-config.ps1"

        #ps1_sysnative
        Get-NetAdapter | Set-DNSClientServerAddress -ServerAddresses (${resource.Cloud_vSphere_Machine_1.dnsSearchOrder})
```
In the example, Cloudbase-init will be instructed to run 3 executions. The first is to use the cloud-config hostname plugin to set the hostname of the machine to the input provided as part of the vRA template. The next two are to run powershell commands to set the IP address and DNS search order for the guest OS. This is just a small example of what could be executed in this phase of the build.

## Detaching the CD-ROM used by Cloudbase-Init & Other Cleanup
vRA passes the above code via the previously mentioned OvfService using an xml file that's attached via the CD drive of the VM. However, neither Cloudbase-init or vRA detach this CD image after processing is finished. Leaving attached CD files can cause vMotion issues in the future, so we generally detach them.

I am currently using a simple solution of creating an ABX action that triggers on the "Compute post provision" phase of a build. (AKA when the VM has finished the build phase). The action is a simple powershell script (using those nifty encrypted action constants!):
```
function handler($context, $inputs) {
    $vcUser = $context.getSecret($inputs.VCUser)
    $vcPassword = $context.getSecret($inputs.VCPass)
    Connect-VIServer -Server vcenter.fqdn -User $vcUser -Password "$vcPassword"-Force
    Get-VM -Name $inputs.resourceNames[0] | Get-CDDrive | Set-CDDrive -NoMedia -Confirm:$false
    return $inputs
}
```

Another cleanup item to note, is the installation of Cloudbase-Init will create a local user on the system named cloudbase-init. You may need to remove or disable that account based on your security policies.

## Closing Thoughts

This is a general summary of a an approach that I found that actually works for me on Windows Server 2016, and 2019 Operating Systems. It is certainly not perfect, and I hope to learn of better methods from the community.
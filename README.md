# All the ways to Windows Server

Team name: **Windows gets no love!**

It's hard to find vRA 8 examples that are Windows specific. So we're part of the solution. We want to make it easier for others to get up and running from everyone's collective learnings!  

Whether base vCenter or vRA, powershell, ansible or saltstack, we will document all the ways to automate windows server deployments, with a fully prepped image. And then we will also do performance testing to see what scales!

## Team Members

[Ariel Sanchez](https://twitter.com/arielsanchezmor)

[Jason 'Willie' Williamson](https://twitter.com/adminwillie)

[Wes Milliron](https://twitter.com/wesmilliron)

[Greg Bates](https://twitter.com/pensrule82)

[Doug DeFrank](https://twitter.com/dougdefrank)

[Eric Macintosh](https://twitter.com/this_emac)

Josh Demcher

[Lucho Delorenzi](https://twitter.com/lgdelorenzi)


## Team Picture

![team pic](https://github.com/vmwcode2021windows/all-the-ways-to-windows-server/blob/main/windows%20gets%20no%20love.png)

Yes, Ariel is soulfully singing to the team

## Section provided by Lucho


### The goal

Lucho kicked off the internal discussion of what we wanted to achieve:

vRA + Cloudbase-init -> whats the end goal? what should our windows image be able to do? a couple ideas:   
1. initialize disks that have been added as part of the deployment  
2. join to AD  
3. adding an AD group to local administrators  
4. download X software from Y location (could very well be installing an IIS role and then downloading a page from somewhere and editing the index file)  
5. install that software  
6. configure that software  
7. execute some kind of test to see everything is working  

I'd be happy if we can get to #3 but also installing a license, creating the computer account in the right OU, and enabling rdp

configure IP/network on the guest if that's not already a given

Use of an IPAM I believe requires the use of vsphere custom specs? Currently, I'm using cloudbase-init to do my naming and IP addressing on the guest, then using ansible to do disk initialization and domain joins. I agree that #3 would make me happy - is the goal to get to #3 via multiple methods? ansible, saltstack, etc?

### A basic walkthrough -  here's a mix of cloudbase-init and vSphere Customization Specification to customize a Windows Deployment in vRA 8

1. First of all, the image needs to be prepared for cloudbase-init to be used 

Documentation: https://docs.vmware.com/en/vRealize-Automation/8.4/Using-and-Managing-Cloud-Assembly/GUID-6A17EBEA-F9C3-486F-81DD-210EA065E92F.html 

Important caveats: A pending sysprep state in the image might cause the customization specification done by vRA when deploying to fail when disconnecting and reconnecting the network interface. If customization specification will be used as well as cloudbase-init, then the sysprep checkbox should be left unchecked 

A customization specification will be triggered in the following scenarios: 

- Manually selecting a customization specification that was created in vSphere with for example, instructions to Join AD 

- If the network has a static assignment. vRA will create and execute a 'phantom' customization specification to configure the network 


To make both work, the following needs to happen: 

- A customization specification that is not the 'phantom' one is created in vSphere 

- Do not select the option to Sysprep the template after cloudbase-init installation 

- Set cloudbase-init service to 'disabled' after completing the installation 

- Add a 'Run Once' command to the customization specification with the following code 

`powershell -command "Start-Process cmd -ArgumentList '/c sc config cloudbase-init start= auto && net start cloudbase-init' -Verb runas" `

- Select 'Log in automatically as administrator' 


This process will keep cloudbase-init disabled until after the commands in sysprep have completed, which is after the last reboot. Then cloudbase-init will kick in and run whatever is there. 
 

2: Creating a cloud template that contains both customization specification as well as cloudbase-init commands 

For example, if we wanted to use a static assignment create a simple file, and then run a script that is located in a network location (for example, to install software), this is what the VM resource in the blueprint would look like: 


resources: 

  Cloud_Machine_1:  
    type: Cloud.Machine  
    properties:  
      image: '${input.image}'  
      flavor: '${input.size}'  
      customizeGuestOs: true  
      newName: '${input.hostname}'  
      customizationSpec: '${input.customSpec}'  
      cloudConfig: |  
        #cloud-config   
        write_files:  
          content: Cloudbase-Init test  
          path: C:\test.txt  
          runcmd:  
            - xcopy \\'${input.scriptLocation}'\scripts\script.ps1 C:\script.ps1 - powershell.exe C:\script.ps1  
      networks:  
        - assignment: static  
          network: '${resource.Cloud_Network_1.id}'  
 

In this case, the inputs are image, size, hostname, customSpec and scriptLocation.  

So if we were to deploy this VM, it would have 

- Static IP Assignment (from an IPAM, either internal or external) 

- Will be joined to the domain using the Customization Specification  

- Will create a file, copy a script from the network, and then run it 


The commands that are run from within cloudbase-init are endless. You can then install/configure software, connect to other servers, or perform any additional configuration you can imagine 

 
## Section provided by Wes

I may be able to provide some content on the basic use of cloudbase-init or leveraging ansible tower for config mgmt.

[Dealing with Cloudbase-init](https://github.com/vmwcode2021windows/all-the-ways-to-windows-server/tree/main/cloudbase-init)

Who did you like better, Lucho's or Wes's ?

### Things to learn

I’m interested to see what the others are doing with vRO and saltstack. 

### Some typical problems Wes brought up and that he handled in his section

Q: For those of you that use cloudbase-init, when the OVF plugin/module does its thing after first boot, I noticed it mounts an XML file to the DVDROM drive. why does that stick around after reboots? is there a way to remove it/tell cb-init to stop attempting to check for any config

A: That was the same behavior I encountered as well. I'm sure there's a better way, but I simply created an ABX action in vRA that triggers on the post-provision phase of a build. The action basically runs a powercli command to disconnect the CD rom of the provisioned VM. I'm all ears to better methods though


## Section provided by Greg

Greg talks to us about managing a Windows fleet and how to get started with SaltStack. He has a really good video on the first topic here - patching, documentation, and reporting with PowerBI  
[Greg's PowerBI video](https://www.youtube.com/watch?v=7mWjs1hDKGE)

Greg is just starting with SaltStack so he's looking for collaboration. He created a section with examples and provided a general overview:

[Starting with SaltStack for Windows](https://github.com/vmwcode2021windows/all-the-ways-to-windows-server/tree/main/SaltStack)  


## Section provided by Eric

Eric provided an excellent section that goes into more detail using vRO and some of the classical approaches, but in vRA8

https://github.com/vmwcode2021windows/all-the-ways-to-windows-server/tree/main/classic-approach  

for joining to AD, i know we could do that in a customization spec, or in vRA or in some method after the server is provisioned - not sure we want mix those up too with our approaches, but I was going to use the AD integration with vRA (since we don't use that in our env today)


## Additional resources

Some HOLs that may help:  

Lightning lab to get familiar with vRA 8 concepts:  
https://docs.hol.vmware.com/HOL-2020/hol-2021-91-ism_html_en/

This one has integration with an IPAM and other extensibility examples  
https://docs.hol.vmware.com/HOL-2020/hol-2021-03-cmp_html_en/


## If we ever get the lab running

Name:    vcsa7.ariel.lab
Address:  192.168.3.151

username: administrator@vsphere.local  
pw: VMware1!

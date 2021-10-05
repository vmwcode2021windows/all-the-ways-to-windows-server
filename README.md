# All the ways to Windows Server
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

## Section for Lucho

vRA8 and Windows 101: Basic walkthrough and documentation links for Windows Server in vRA 8

Taken from Slack:

so im doing vRA + Cloudbase-init -> whats the end goal? what should our windows image be able to do? a couple ideas:   
1: initialize disks that have been added as part of the deployment  
2: join to AD  
3: adding an AD group to local administrators  
4: download X software from Y location (could very well be installing an IIS role and then downloading a page from somewhere and editing the index file)  
5: install that software  
6: configure that software  
7: execute some kind of test to see everything is working  

I'd be happy if we can get to #3 but also installing a license, creating the computer account in the right OU, and enabling rdp

configure IP/network on the guest if that's not already a given

Use of an IPAM I believe requires the use of vsphere custom specs? Currently, I'm using cloudbase-init to do my naming and IP addressing on the guest, then using ansible to do disk initialization and domain joins. I agree that #3 would make me happy - is the goal to get to #3 via multiple methods? ansible, saltstack, etc?

## Section by Wes

I may be able to provide some content on the basic use of cloudbase-init or leveraging ansible tower for config mgmt.

[Dealing with Cloudbase-init](https://github.com/vmwcode2021windows/all-the-ways-to-windows-server/tree/main/cloudbase-init)

### Things to learn

I’m interested to see what the others are doing with vRO and saltstack. 

### Some typical problems Wes brought up and that he handled in his section

Q: For those of you that use cloudbase-init, when the OVF plugin/module does its thing after first boot, I noticed it mounts an XML file to the DVDROM drive. why does that stick around after reboots? is there a way to remove it/tell cb-init to stop attempting to check for any config

A: That was the same behavior I encountered as well. I'm sure there's a better way, but I simply created an ABX action in vRA that triggers on the post-provision phase of a build. The action basically runs a powercli command to disconnect the CD rom of the provisioned VM. I'm all ears to better methods though


## Section for Greg

Greg talks to us about managing a Windows fleet and how to get started with SaltStack. He has a really good video on the first topic here - patching, documentation, and reporting with PowerBI  
[Greg's PowerBI video](https://www.youtube.com/watch?v=7mWjs1hDKGE)

Greg is just starting with SaltStack so he's looking for collaboration. He created a section with examples and provided a general overview:

[Starting with SaltStack for Windows](https://github.com/vmwcode2021windows/all-the-ways-to-windows-server/tree/main/SaltStack)  


## Section For Eric

Document these two methods

for joining to AD, i know we could do that in a customization spec, or in vRA or in some method after the server is provisioned - not sure we want mix those up too with our approaches, but I was going to use the AD integration with vRA (since we don't use that in our env today)


## Additional resources

Some HOLs that may help:  

Lightning lab:  
https://docs.hol.vmware.com/HOL-2020/hol-2021-91-ism_html_en/


This one has integration with an IPAM and other extensibility examples  
https://docs.hol.vmware.com/HOL-2020/hol-2021-03-cmp_html_en/


## If we ever get the lab running

Name:    vcsa7.ariel.lab
Address:  192.168.3.151

username: administrator@vsphere.local  
pw: VMware1!

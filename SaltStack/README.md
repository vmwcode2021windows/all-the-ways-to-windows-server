The most important thing about managing a large Windows environment is to have a consistant image and configuration across as many systems as possible.  The best way to manage this is through Group Policy. Group Policy is great if you want everything the same.  But there are always going to be exceptions and new changes are difficult to roll out and test.

## Common Windows management
A common solution to managing and deploying Windows is to have a VMware Template + Customization Specs + PowerShell.

Challeges with this include
 1. Non-VMware Workloads like bare metal and Cloud.
 2. Non-domain joined Workloads (no GPO)
 3. Slow change roll outs (GPO updates are all or none)
 4. Compliance and reports on machine configs.  

## Saltstack Windows management

Saltstack can manage Windows through Salt States.  You can create a simple YAML based configuration to run on groups of servers(Minions) to roll out small changes and save this config for future builds as a general configuration.  

Sample salt state Configurations:
1. LGPO (Local Group Policy) changes
2. Registry configuration - Add, check, change or remove
3. Service Configuration - Check state and edit
4. NIC configurations - DNS changes, IP changes, Domain adds.
5. Package installations. 

My vision is to build a full configuration for a Windows build and have SaltStack check and update new builds as necessary, where it doesn't matter if it is a VMware VM, Bare Metal Windows installs, cloud workloads or non-domain joined workloads.  They can all be managed the same way.  As we make small changes, we can rollup these changes into images or GPO's but the config is never lost and can be run regadless to maintain state. 

Some things will still need PowerShell to work, but SaltStack makes it pretty easy to call any powershell script.

## SecOps

With the SecOps add on you can report on compliance to expected configuration drift.  By default you can check against CIS compliance, but you can also build your own compliance and check against a custom configurations.  Once checked you can force it back if you want or schedule a time to revert the change back if you would like.

## Examples

I added a couple of very simple salt state examples in YAML format.
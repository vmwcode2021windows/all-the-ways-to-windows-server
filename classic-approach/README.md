# Classic Approach
The classic approach to building a Windows server consists of using vRealize Automation (vRA) in conjunction with vRealize Orchestrator (vRO) and Action Based Extensibility (ABX).

The end result of this solution is a Windows server, with an addtional disk on the E: drive, a specified user in the local administrators group and Notepad++ installed.

## Overview
This solution uses the native features of vRA to build a Windows servers.  There are multiple components that each play an important role in the overall process.

**Component** | **Description**
----------|--------------
Cloud Account | The vCenter where the server will be built
Cloud Zone | The available clusters/hosts for a server build
Project | Represents the group that will have access, permissions are supplied here
Cloud Template | The "blueprint" for the server deployment - consists of the building blocks
Image Mappings | Defines the machine templates to use for a build
Flavor Mappings | Defines the size of a server build (cpu/mem)
Network Profile | Defining available networks and ranges for a deployment
ACtive Directory Integration | Allows for accounts to be created in AD
Event Broker Subscription | Entry point to into different phases of the build process
ABX Actions | Custom code that can be called by an Event Broker Subscription
vRO Workflows | Custom workflows that can be called by an Event Broker Subscription

## High-level Flow
Without wading into the weeds, these are the steps that make up this classic approach to building a server with vRA
1. The components on the cloud template are processed
1. Based on the tagging strategy, the compute for the server will be chosen
1. Based on tagging, the network for the server will be used
1. The account will be pre-created in Active Directory
1. The server will be provisioned in vCenter
1. An account will be added to the local admin group with a vRO workflow
1. The attached disk will be intialized/formatted with an ABX action
1. Notepad++ will be installed on the server with a vRO workflow

## Components
In this section, we'll elaborate a bit more on some of the components.

#### Cloud Template
The cloud template consists of three objects:
* Cloud.vSphere.Machine
* Cloud.vSphere.Network
* Cloud.vSphere.Disk

There are three inputs definted in the cloud template:
* os_version
* flavor
* localAdmin

There are four custom properties on the machine object
* image (from the os_version input)
* flavor (from the flavor input)
* localAdmin (from the localAdmin input)
* customizationSpec (an os customization spec in vcenter that includes domain join)

#### Image Mapping
There are two flavor mappings defined for the cloud account, they each point to a valid template in vCenter:
* win2k16
* win2k19 

#### Flavor Mappings
There are three flavor mappings defined
* Small
* Medium
* Large

#### Network Profiles
There is one network profile defined, consisting of two networks.  Each network has IP Ranges defined.  In this particular set up, vRA is acting as the IPAM and will choose an available IP for the server build.

#### Active Directory Integration
The Active Directory integration was added and configured to point to a valid AD instance.  And an OU was specified for the Project that will be building servers.

With this integration, vRA will pre-create the computer account for a server build by this project in the OU specified.  This integration supports the ability to overwrite the OU or skip the integration entirely with additional settings in a cloud template.

#### Project
The project has been given access to provision in the required cloud zones.  The project has also been given a simple default naming convention, so the user doesn't need to specify a server name during the build process.

#### Event Broker
There are three Event Broker Subscriptions configured for this process, each for the Compute Provision Post event (after the server has been provisioned)
* Add Local Admin (calls vRO)
* Format Disk (calls ABX)
* Install Notepad++ (calls vRO)

#### vRO - Add Local Admin
This workflow:
* Parses the server name and local admin account from inputProperties payload
* Prepares a PowerShell script to add the account to local admins
* Uses built-in workflow to get the VM Object with that name
* Uses built-in workflow to run a program on the guest OS, passing the local path powershell and the script as arguments

#### vRO - Install Notepad++
This workflow works nearly the same as the one to add a local adminstrator
* Parses the server name from the inputProperties payload
* Prepares a PowerShell script to download and install Notepad++
* Uses built-in workflow to get the VM Object with that name
* Uses built-in workflow to run a program on the guest OS, passing the local path powershell and the script as arguments

#### ABX - Format Drive
This ABX action works similar to the vRO workflows, but is less modular.  It's written in PowerShell
* Connects to the vCenter (user/pwd params stored as Action Constants)
* Prepares a script to initialize/format the disk and assign to E: drive
* Uses invoke-vmscript to run the script on the VM (user/pwd params stored as Action Constants)

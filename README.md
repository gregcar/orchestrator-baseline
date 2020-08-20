> **Important:** The user running this template needs to be an **Owner** on the subscription or Resource Group where your Virtual Network is located.

`Tags: AKS, Kubernetes, Advanced Networking, Azure Active Directory`

## Solution overview and deployed resources

Executing an AKS deployment using this ARM template will create an AKS instance. However, it will also assign the selected Service Principal the following roles:
- 'Network Contributor' role against the pre-existing subnet.
- 'Contributor' role against the automatically created resource group that contains the AKS cluster resources.

It will also setup Azure Active Directory as the default Authentication mechanism for your cluster. This will allow you to setup Kubernetes RBAC based on users identity of group membership. There are a couple of limitations that apply to this scenario though:

- Azure AD can only be enabled when you create a new, RBAC-enabled cluster. You can't enable Azure AD on an existing AKS cluster.
- Guest users in Azure AD, such as if you are using a federated login from a different directory, are not supported.

## Prerequisites

Prior to deploying AKS using this ARM template, the following resources need to exist:
- Azure Vnet, including a subnet of sufficient size
- Service Principal
- Azure AD Server Application - [instructions here](https://docs.microsoft.com/en-us/azure/aks/aad-integration#create-server-application)
- Azure AD Client Application - [instructions here](https://docs.microsoft.com/en-us/azure/aks/aad-integration#create-client-application)

The following Azure CLI command can be used to create a Service Principal:

_NOTE:  The Service Principal Client Id is the Same as the App Id_

```shell
az ad sp create-for-rbac -n "spn_name" --skip-assignment
az ad sp show --id <The AppId from the create-for-rbac command> --query objectId
```

Please note that using the 'create-for-rbac' function would assign the SPN the 'Contributor' role on subscription level, which may not be appropriate from a security standpoint.
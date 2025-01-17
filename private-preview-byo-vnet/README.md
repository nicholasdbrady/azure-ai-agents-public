# 🤖 Azure AI Agent Service – Private Virtual Network Setup Guide 🤖

 | [**Get started**](./quickstart-python.md) |

Build fast, secure enterprise AI Agents to automate any business workflow

> [!IMPORTANT]
> This feature is currently in private preview. Only select customers have been approved to participate in this preview.

## ❓What is the Azure AI Agent Service?

Azure AI Agent Service is a fully-managed service designed to empower developers to securely build, deploy, and scale high-quality, and extensible AI agents. Leveraging an extensive ecosystem of models, tools and capabilities from OpenAI, Microsoft, and third-party providers, Azure AI Agent Service enables building agents for a wide range of generative AI use cases.

## Private Preview Instructions

Hi there 👋

We are excited to welcome you to the private preview of our latest feature, **Azure AI Agent Service with private virtual network support**.  

During this preview, we encourage you to explore the setup described in this guide and provide feedback. Your insights are invaluable in refining the service ahead of its public preview release next year.

To provide feedback and/or file bugs, please use this template: [Azure AI Agent Service – Private Virtual Network Feedback](https://nam.dcv.ms/ziC6GBEbTS).

We are committed to supporting you throughout this private preview phase. Should you have any questions or require assistance, please do not hesitate to reach **azureagent-preview@microsoft.com**.

Thank you for being a part of this exciting journey. We look forward to your participation and valuable feedback.

## Overview - Azure AI Agent Service with Private Virtual Network

Azure AI Agent Service allows users to **BYO (Bring Your Own) private virtual network with the standard agent setup**. This configuration establishes an isolated network architecture that enables customers to securely retrieve data and execute actions while maintaining complete control over their network environment. This guide walks through the setup process and requirements.

### Security Benefits of BYO Virtual Network

- **No public egress**: foundational infrastructure ensures the right authentication and security for your agents and tools, without you having to do trusted service bypass.

- **Container injection**: allows the platform network to host APIs and inject a subnet into your network, enabling local communication of your Azure resources within the same virtual network (VNet).

- **Private resource access**: If your resources are marked as private and non-discoverable from the Internet, the platform network can still access them, provided the necessary credentials and authorization are in place.

### Regions Supported

The following Azure regions are currently supported for private virtual networks:

- East US
- West Central US
- West US
- West US 3
- Japan East
- UK South
- France Central
- Korea Central

### Known Limitations

- Azure Blob Storage: Using Azure Blob Storage files with the File Search tool is not supported.

## 🚀 Get Started

See the QuickStart to [get started](./quickstart-python.md).

# MBO Server Setup
This repository includes all the key files you need to get the MBO server up and running. It also provides clear instructions to guide you through the process. Included in this repository is a script that automates the setup process. This script creates the required files and directories, and installs the necessary software for the server.

## Usage
To get started download the repository and run the script to create all necessary files for the server:
```bash
git clone https://github.com/activcoding/MBO-Server-Setup.git && cd MBO-Server-Setup && chmod +x ./mbo-init.sh && ./mbo-init.sh
```

> [!IMPORTANT]
> You have to manually add the `firebase-admin.json` file to the directory.

## Firebase Cloud Messaging
To send push notifications, the server uses Firebase Cloud Messaging.
The only thing that is needed is the `firebase-admin.json` file in the root directory of the project.
You have to create a Firebase project and follow those steps:
1. Select your project, and click the gear icon on the top of the sidebar.
2. Head to project settings.
3. Navigate to the service account tab.
4. Click Generate New Private Key, then confirm by clicking Generate Key.
5. Clicking Generate Key downloads the JSON file.
6. Rename the file to `firebase-admin.json` and place it in the root directory of the project.

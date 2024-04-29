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

## Add an admin to the MBO-API-Database
In order to add an admin for the MBO-App, you'll have to first insert an admin manually into the database.
To do that the mongo container has to be up and running. Then enter the container with:
```bash
docker exec -it mongo mongosh
```
Move to the mongo admin database(not the admins database for the MBO-App):
```bash
use admin
```
Authenticate yourself(the username and password are the ones you set in the `.env` file):
```bash
db.auth("username", "password")
```
or 
```bash
db.auth("username", passwordPrompt())
```
The output should look like this:
```json
{ ok: 1 }
```
Now we can insert the admin, first move to the MBO-App database:
```bash
use MBO-APP-API
```
Insert the admin:
```bash
db.admins.insertOne({ 
  "_id": ObjectId(), 
  "email": "name.lastname@mbo.schule",
  "name": "Name Lastname" 
})
```
If the admin is successfully created, you should see something like this:
```json
{
  acknowledged: true,
  insertedId: ObjectId('662d4c0c28fbb11a9a2202d8')
}
```
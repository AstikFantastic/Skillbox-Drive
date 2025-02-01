# Skillbox-Drive
A simplified app for using Yandex Disk 

## General Information  
- This app provides access to user files on Yandex Disk.  
- Users can browse files and directories stored on their disk.  
- Supports downloading existing files.  

## Technical Requirements: Usage Scenarios 

Below is a full description of the usage scenarios. Each scenario has one of three statuses:  
✅ - Implemented  
🚧 - In development  
❌ - Not implemented

⚠️ An implemented feature may be in beta testing and subject to change over time ⚠️

### Onboarding  
✅ The onboarding screen is displayed immediately upon the first launch of the app.  
(⚠️ To show the onboarding again, you need to switch the app to the background in the simulator and restart the project)

### Authentication  
✅ The login screen always appears after onboarding.  
❌ Using the app without logging in is not allowed 
(⚠️ After pressing the login button, the app navigates to the TabBar screen with information about the user's Yandex Disk) 

### View Disk Information  
✅ The profile screen displays available information about the current state of the user's disk, including total disk size and used space.  
✅ Additionally, a circular chart should be displayed to visualize these values.

### View Recently Uploaded Files  
✅ A list of the most recently uploaded files is displayed. For each file, the following information is shown: icon or preview, name, upload date and time, and size.  
❌ A loader is shown when the file icon is loading.  
❌ The list is paginated.  
❌ The list is cached in the database.  
❌ If there is no network connection, cached files from the database are displayed with a notification to the user.  


### View Detailed File Information  
✅ When the user taps on a file in the list, they are redirected to the file view screen.  
❌ If the file is not yet downloaded from the server, the user sees the download status.  
✅ The app supports viewing the following file types:  
  - Images  
  - PDFs (using PDFView)  
  - MS Office files (using WKWebView)  
🚧 On the file view screen, the user can see the file name, creation date, and time.
❌ The following actions are available on the file view screen:  
  - Share the file with other apps  
  - Share a link to the file  
  - Delete the file  
  - Rename the file  

### Share a Link to a File  
❌ On the file view screen, the user can tap the "Share" button in the toolbar.  
❌ A link to the file is generated, which can be shared with other apps.  

### View Files and Directories List  
🚧 Tapping the "All Files" tab opens a list of files and directories on the disk.  
✅ The behavior of the list is similar to the list of recently uploaded files.  
❌ Tapping on a folder opens the same screen showing the contents of the selected directory.  
❌ Where possible, information about the retrieved files and directories is cached.  

### View Published Files and Directories List  
❌ Tapping on the "Published Files" option in the profile opens a list of published files and directories on the disk.  
❌ The behavior of the list is similar to the list of recently uploaded files.  
❌ Tapping on a folder opens the same screen showing the contents of the selected directory.  
❌ For each published item, there is an option to unpublish it. Once unpublished, the item disappears from the list.  
❌ Where possible, information about the retrieved files and directories is cached.  

### Log Out  
❌ Tapping the "Log Out" button in the profile shows a dialog: "Are you sure you want to log out? All local data will be deleted."  
❌ If the user confirms, the app logs out and deletes all local data.  
❌ After clearing data and on subsequent app launches, the login screen is shown.  




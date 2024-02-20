##################################################
# Script  : AD-Support 
# Author  : Noel Williams
# Updated : 15/02/2024 

################################################## 
# can search for groups using parts of the group name and displays name and description of group
# can use a list of usernames or emails and script will take all users if valid and add to a specified AD group
#

function addUsersToGroup {
    echo ""
    echo "Adding list of users to group"
    echo "Please copy and paste the file with usernames or emails into the current folder and use ./filename.txt when prompted or use the full path."
    echo "Must be only usernames or only emails."
    echo ""
    $groupName = Read-Host "What is the name of the group you would like to add users to?"
    echo ""
    $membersBefore = ((get-adGroup -filter "Name -like '$groupName'" -Properties Members).Members | measure).Count

    echo "Group members count before add: $membersBefore" 
    echo ""

    $filePath = read-host "What is the path to the file e.g .\filename.txt"
    echo ""

    
    try {
        $userData = Get-Content -Path $filePath -ErrorAction Stop
        $group = Get-ADGroup -Identity $groupName -ErrorAction Stop
    } catch {
        if ($Error[0].Exception.GetType().FullName -eq [System.Management.Automation.ItemNotFoundException]) {
            echo "File: $filePath not found, is the path correct?"
        } elseif ($Error[0].Exception.GetType().FullName -eq [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]) {
            echo "Group: $groupName could not be found please search group and use full and correct group name."
        }
        
        exit
    }
    
    

    $groupSAM = $group.SamAccountName
    

    function typeCheck {
        $dataType = Read-Host "What does the file contain?`n1.Usernames`n2.Emails?`n"

        if ($dataType -ne "1" -and $dataType -ne "2") {
            echo "Error: Enter either 1 or 2!"
            $data = typeCheck
            if( $data -eq "1" ){
                return "SamAccountName"
            } else {
                return  "EmailAddress"
            }
        } else {
            if( $dataType -eq "1" ){
                return "SamAccountName"
            } else {
                return  "EmailAddress"
            }

        }
    }

    $dataType = typeCheck

    $count = 0
    $usersNotFound = ""
    $errorH = ""
    foreach($line in $userData) {
        try {
            echo $dataType
            $user = Get-ADUser -Filter "${dataType} -like '${line}'" -Properties *
            if($user) {
                $uname = $user.SamAccountName
                $count++

                Add-ADGroupMember -Identity $groupSAM -Members $uname
                #echo "User $uname added"

             } else  {
                $usersNotFound += $line + "`n"
                #echo "no user with data: $line"
            }

         

        } catch {
            $errorH += $line + "`n"
        }
   
  
    }
    $usersNotFound += $errorH
    echo "Users added count: $count"

    Set-Content -Path "./UsersNotAdded.txt" -Value $usersNotFound
    echo "Data that did not match any users saved to text file: ./UsersNotAdded.txt"

    $membersAfterAdd = ((get-adGroup -filter "Name -like '$groupName'" -Properties Members).Members | measure).Count

    echo "Group members count before add: " + $membersBefore
    echo "Group members count after add: " + $membersAfterAdd
    

}

function checkGroup {
    echo "Group Search"
    echo ""

    $groupName = Read-Host "What does the group name contain? "

    $val = get-adGroup -filter "Name -like '*$groupName*'" -Properties * | FT Name, Description
    echo $val
}

function options {
    echo ""
    $choice = Read-Host "Please enter what you would like to do?`n1. Add List of users to group.`n2. Search for group and show details.`n"

    if($choice -ne "1" -and $choice -ne "2") {
        echo "Error choose valid option."
        options

    } else {
        if( $choice -eq "1") {
            addUsersToGroup
        } elseif($choice -eq "2") {
            checkGroup
        }
    }
}

function main {

    echo "ADSUP v1"
    echo "Developed by NW"

    options

}

main

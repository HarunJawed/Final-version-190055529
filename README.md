[![Open in Visual Studio Code](https://classroom.github.com/assets/open-in-vscode-c66648af7eb3fe8bc4f294546bfd86ef473780cde1dea487d3c4ff354943c9ae.svg)](https://classroom.github.com/online_ide?assignment_repo_id=9973734&assignment_repo_type=AssignmentRepo)
EExDSH Practical Starting and Submission Instructions
=====================================================

We will be using github (and github classroom) to get the initial template for your practical work, for version control of your work, to submit your work regularly and to get feedback on your submitted work. I also recommend using Visual Studio Code to edit and manage your work as this provides good support for VHDL as well as other languages and integrates easily with github. These are all modern industry standard tools for software development.

1. If you have not already done so register for account on [GitHub](https://github.com/). 
   We recommend using a username that incorporates your name.

2. In order to create a repository for you work starting from my coursework template you will need 
   to go to the classroom invite link for this class [EExDSH Classroom](https://classroom.github.com/a/uxU3I8Ao)
    
3. On the class invite page click on your student id - this will generate a repository for you and after a 
   short delay you will get the link for your repository - copy this to the clipboard.
    
4. Open Visual Studio Code on your working system. If you start from a new Window - click on the option "Clone Git Repository". 
   THis will ask you for the github link to clone from (which you got above) and a directory into which to create your work.
    
5. Once completed Visual Studio Code will be open for you to continue your work. 
   You will find the practical workbook and an example of how to document your instruction set in the docs subfolder.
    
6. If you have not previously done so set your username and email for git. Open a command line terminal use the following commands to set these

            git config --global user.name "FIRST_NAME LAST_NAME
            git config --global user.email "youremail@aston.ac.uk"
    
7. **Commit Early and Often**  Git only takes full responsibility for your data when you commit. 
   If you fail to commit and then do something poorly thought out, you can run into trouble. 
   Additionally, having periodic checkpoints means that you can understand how you broke something. 
   Make sure you have saved all of your files. Go to the "Source Control" panel in Visual Studio Code, enter an appropriate message about the changes you have made, push "Commit"  and then select "Save all and Commit" when asked. Note: If you have manually staged changes then only those will be saved however if you adopt the "Commit Early and Often" approach Save all and commit is usually the best option.

8. *Push/Synchronise your work onto your github repository when you have completed any of the tasks and 
   at least at the end of every practical session*. The tutors will then be able to view your work and given feedback and suggestions via github.
   Same as above but select the "Commit and Push" option instead of "Commit".

9. **Commit and push your final work for assessment** - you will be assessed on your last commit
   before the coursework deadline. This will be marked using the attached marking spreadsheet.
    
10. You may get formative feedback on individual commits or overall feedback in your repository on github.
    
11. I recommend installing the "VHDL by VHDLwhiz" extension from the extensions panel on Visual Studio code to get syntax hilighting etc.

12. Open a command line terminal at the bottom of the Visual Studio Code screen to run the various make commands
    mentioned in the lab script which will be found inthe docs folder of your working directory.

Submission of work for summative assessment
-------------------------------------------

At the end of this practical you are required to submit your working files for feedback and assessment. You
must follow the instructions below. Failure to follow these instructions exactly will result in a mark of 0 being awarded for the
specific component where you have diverted from them.

* **Filenames**  *must be exactly* as specified in the exercises including case.

* **Time and Collaboration info** Make sure that you have entered
  your name and any collaborators  at the start of each code
  source file.

        -- EExDSA 2022 Term 2
        -- Name: Jan Lee
        -- Collaborators: John Doe
        --

        ---... your code goes here ... 

* **Results** Make sure that you have generated all the necessary simulation
  waveform and binary bit files and that they are present in you
  working directory. These should all be included in your commit.

* **Github Submission** The submission should be on your *main* branch - it you have been using different branches to
  manage changes to your code make sure that you have merged all changes into the *main* branch, and you are on that branch prior to submission.
  In Visual Studio Code, under source control, ensure all changed files have been selected and select **Commit and Push**. 
  Enter "Final Submission" as the commit message. 

Copyright (C) [2022] Aston University
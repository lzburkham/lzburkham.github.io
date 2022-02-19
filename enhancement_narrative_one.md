# Logan Burkham ePortfolio 
#### [Portfolio Home](./README.md) > [Enhancement One Narrative](./enhancement_narrative_one.md)

## Enhancement One (Software Desgin and Engineering)
The artifact that I am refining for the Software Design/Engineering category of the course outcome is a logging script that I wrote for Abilene Christian University to gather user access logs from the Azure AD SSO integration of the Ebsco Library Online software. This script is used to gather these logs and quantify data within the university ERP database. This script was written in 2021 to meet the reporting needs of the ACU Library for the multi-campus institutional user base.

This artifact is actually inclusive of all of the components of the intended course outcomes. I feel that it demonstrates a piece of software that can be improved to showcase the improvements that I have made as a software developer since writing it nearly a year ago, as well as showcases the amount of thought that was put into the project at its inception. Specifically, the use of the imported modules to make the creation and manipulation of the data that is accessed from the ERP database to be reported on showcases my initial abilities in software development. However, this artifact has been improved (with regard to software development/engineering) by implementing a clearer Object-Oriented Programming methodology and including the python industry standard “if-dunder-name-is-dunder-main” case statement. This change showcases the improvements I have made as a backend developer since this script was created.

The changes that I implemented do meet the course objectives that I had initially planned to meet with this enhancement. Specifically, the following points were attributed to with these enhancements: 
- Design and evaluate computing solutions that solve a given problem using algorithmic principles and computer science practices and standards
appropriate to its solution, while managing the trade-offs involved in design choices (data structures and algorithms)
- Demonstrate an ability to use well-founded and innovative techniques, skills, and tools in computing practices for the purpose of implementing
computer solutions that deliver value and accomplish industry-specific goals (software engineering/design/database)
That is not to say that these points will not find additional value with the next planned enhancements to this script. These simply were the most effectively and holistically met program outcomes that were met with these enhancements.

Overall, enhancing this script with the changes made was valuable for me in understanding the pythonic operation even further. While, initially, I thought that I would simply be placing the entirety of the script in a user defined main() module, I found that breaking the script up into individual objects allowed for the script to be more robust overall. I was able to require closed connections by calling the close_cnx() method directly and passing my connection with the call rather than checking to see if a connection exists and closing near the termination of the script as a whole. I also rearranged the objects a bit so they read more clearly to a user that may have to take up modifying this script at a later date. Additionally, the addition of the “if-dunder-name-is-dunder-main” case statement provides a level of security since this implementation limits the execution of the script to a specific call to this script rather than from any other script. The splitting of the script into separate objects proved to be the best method for implementation of this script and has improved how robust the script is in general.

The code base for this enhancement can be [viewed here](./enhancement_one.md) and [downloaded here](./ebsco_access_logs_SNHU_Module_3/main.py)

###### [Portfolio Home](./README.md) | [Code Review](./code_review.md) | [Narratives & Enhancements](./narratives_and_enhancements_lander.md) | [Contact](./contact_me.md)

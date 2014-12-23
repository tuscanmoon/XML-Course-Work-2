(: Query Prolog :)
declare namespace cnd = "http://webspace.stu.qmul.ac.uk/~ac08162/amcm043/coursework2/candidate";
declare namespace exm = "http://webspace.stu.qmul.ac.uk/~ac08162/amcm043/coursework2/examiner";

(: Wrap the entire document in a <examinerChoice> element :)
<examinerChoice>
{
(: List of University of London Colleges :)
let $collegeList := doc("UniversityOfLondonColleges.xml")//collegeName

(: Candidate PhD Details :)
let $candidate := doc("testCandidate.xml")/cnd:candidate

(: Reference table for priority names, used in loopup code within the return statement :)
let $priorityNames :=   <priorityName>
                            <priority code="1" name="Ideal - Both candidates have University of London PhD examiner experience"/>
                            <priority code="2" name="Possible - One candidate has University of London PhD examiner experience"/>
                            <priority code="3" name="Fallback - None of candidates have University of London PhD examiner experience"/>
                        </priorityName>


(: Set definition and for loop for local examiners :)
for $localExaminar in doc("examiners.xml")//exm:examiner[(exm:academicPost/exm:currentPost/exm:institution = $collegeList)]
let $localExaminarDetails := $localExaminar/exm:personalDetails
let $localExaminarExperience := $localExaminar/exm:previousExperience/exm:experience//exm:institution

(: Set definition and for loop for external examiners. Note the negation of the college check :)
for $externalExaminar in doc("examiners.xml")//exm:examiner[not(exm:academicPost/exm:currentPost/exm:institution = $collegeList)]
let $externalExaminarDetails := $externalExaminar/exm:personalDetails
let $externalExaminarExperience := $externalExaminar/exm:previousExperience/exm:experience//exm:institution

(: If either examiner has London experience then mark the pair as Preferred, else mark them as Possible :)
let $examinarPairPriority := (if ($localExaminarExperience = $collegeList and $externalExaminarExperience = $collegeList) then "1" 
                        else if ($localExaminarExperience = $collegeList or $externalExaminarExperience = $collegeList) then "2"
                        else "3")


(: Additional checks to ensure alignement of subject areas and to not include candidate supervisor in the pair list :)
where $localExaminar/exm:subjectArea = $candidate/cnd:subjectArea
and   not($localExaminar/exm:personalDetails/exm:localIdentificationNumber = $candidate/cnd:PhDDetail/cnd:PhDSupervisorID)
and   $externalExaminar/exm:subjectArea = $candidate/cnd:subjectArea
and   not($externalExaminar/exm:personalDetails/exm:localIdentificationNumber = $candidate/cnd:PhDDetail/cnd:PhDSupervisorID)

(: Place those Preferred examiner pairs to the top of the resultant XML document :)
order by $examinarPairPriority

(: Output examiner pair document details :)
return <examinerPair> 
<priority> {data($priorityNames/priority[@code = $examinarPairPriority]/@name)} </priority>
<localExaminar> {$localExaminarDetails} </localExaminar>
<externalExaminar> {$externalExaminarDetails} </externalExaminar>
</examinerPair>
}
</examinerChoice>
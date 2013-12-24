#! /bin/bash
### This script parses the input CSV file, gets each record and generates
### appropriate PDF payslips
### Required files - payslip_content_1.sgml and payslip_content_2.sgml

### Usage: generatePDFs.sh <input CSV file> <Salary Month> <Salary Year>
### Output: Generates pdf files and zips them into a single archive

TMP_SGML=tmp.sgml
SGML=payslip_content.sgml
SGML_1=payslip_content_1.sgml
SGML_2=payslip_content_2.sgml
GEN_FILES=Generated_files.list
INPUT_CSV=""
FILE_PREFIX=""
ZIP_FILE=payslips_`date +%d%b%Y`_`date +%k%M`.zip
USAGE="Usage: `basename $0` <csv file> <filename>\n\tNote: Filename is optional."
SALARY_MONTH=""
SALARY_YEAR=""

# -- nk Binaries required
BIN_SENDEMAIL=sendEmail

##entries=( entSlNum Source Client ReportingManager entName entDoj SBU CTCInput SplAllInput entLOP entNDP Basicrepeat HRArepeat Convrepeat Medrepeat SplAllowrepeat LTArepeat PFEmployer Bonus ProjectAllowance Gratuity ESIEmployer entGross entBasic entHRA entConveyance entMedical entSpecial entLTA entGAE entPF entPTax entESI entITax entTransport entInsurance entCrederity entExcPaid entTotalDed entNetPayRnd ShiftAllow OverTime NoOfDaysrepeat TotalExtra NetEarnings ProjectAllowance Bonusrepeat Gratuityrepeat entBankName AccountNo entDesignation entPFnum entAmtInWords entEmpID entEmailID) 

entries=(
entSlNum
Source
Client
ReportingManager
entName
entDoj
SBU
CTCInput
entLOP
entNDP
Basicrepeat
HRArepeat
Convrepeat
Medrepeat
SplAllowrepeat
entGross
entBasic
entHRA
entConveyance
entMedical
entSpecial
entGrossEarned
entPF
entPTax
entITax
entExcPaid
entTotalDed
entNetPayRnd
entBankName
AccountNo
entDesignation
entPFnum
entAmtInWords
entEmpID
entEmailID)

# -- nk  CHECK these 
#entNSA_CHECK
#entNDP_CHECK

if [ "$#" -eq 0 ]
then
	echo -e $USAGE
	exit
fi

if [ "$#" -gt 3 ]
then
	echo -e $USAGE
	exit
fi

if [ ! -e "$1" ]
then
	echo "$1: Not found !"
	echo -e $USAGE
	exit
fi

INPUT_CSV=$1

if [ -n "$2" ]
then
	SALARY_MONTH=$2
else
	SALARY_MONTH=`date +%b`
fi

if [ -n "$3" ]
then
	SALARY_YEAR=$3
else
	SALARY_YEAR=`date +%Y`
fi

rm -f $GEN_FILES
touch $GEN_FILES

### Traverse every record in the CSV file and extract the fields
### and generate PDF
cat "$INPUT_CSV" | (
while read line
do
	### Add docbook header
	cat $SGML_1 > $SGML
	#echo $line
	#exit
	### Set command line delimiter to comma instead of space
	IFS=,
	count=0
	fieldFlag=0
	slNo=0
	### Get all fields
	for field in $line
	do
		#if [ $count == 1 ]
		#then
		#	name=${entries[$count]}
		#fi
		# Get the serial number
		if [ $fieldFlag == 0 ]
		then
			let "slNo = $field"
			let "fieldFlag = 1"
		fi

		# -- nk
		#echo "FIELD:  " $field;
		echo -n "<!ENTITY ${entries[$count]} \"" >> $SGML
		field=`echo -n "$field" | cut -d '"' -f 2`
		echo "$field\">" >> $SGML
		let "count += 1"
	done
	### Last field is the email, which will be the filename
	email=$field
	### Add salary month and year
	echo "<!ENTITY entMonth \"$SALARY_MONTH\">" >> $SGML
	echo "<!ENTITY entYear \"$SALARY_YEAR\">" >> $SGML
	### Attach any other filename prefix if specified
	pdfname=${email}_${SALARY_MONTH}${SALARY_YEAR}_${slNo}.pdf
	cat $SGML_2 >> $SGML
# exit # REMOVE THIS -- ksb
	### Create the PDF file
	echo -n "Generating $pdfname... "
	#docbook2pdf $SGML &> /dev/null
	docbook2pdf $SGML
	mv -f `echo -n $SGML | cut -d '.' -f 1`.pdf $pdfname
	### Store the filename for removal later
	echo "$email;$pdfname" >> $GEN_FILES
	echo "Done"
done )
# exit # REMOVE THIS -- ksb

# echo -n "Archiving all the PDF files to \"$ZIP_FILE\"... "
logfile=`echo -n $ZIP_FILE | cut -d '.' -f 1`.log
for line in `cat $GEN_FILES`
do
	# Mail file to the appropriate user
	file=`echo -n $line | cut -d ';' -f 2`
	mailId=`echo -n $line | cut -d ';' -f 1`
	subject="Payslip for $SALARY_MONTH $SALARY_YEAR..."
	echo -n "Sending $file to $mailId... "


	# sendEmail -t $mailId -u $subject -a $file -o message-file=./message.txt -s smtp.emailsrvr.com -xu sunil.b@vaultinfo.com -xp Welcome1 -f vault-payslips@vaultinfo.com -l $logfile -q
	# zip all the files and delete pdf
	# zip -u "$ZIP_FILE" "$file"
	zip -u "$ZIP_FILE" "$file" &> /dev/null
	echo "Done"
	rm -f $file
done
echo "All PDF files saved to \"$ZIP_FILE\""
echo "Done"

echo "Output: $ZIP_FILE"
#exit


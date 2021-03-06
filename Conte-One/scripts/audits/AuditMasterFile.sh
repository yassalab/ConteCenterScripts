#!/bin/bash
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This script created a Master Spreadsheet to track the data from Conte-One. Additional Columns will be 
added as processed data is generated. A copy of the master spreadsheet will be regularily updated on 
google docs for all researchers to access.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

source=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits/sources/ConteMRI_All_Timepoints_Original.csv
FINAL_OUTPUT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/datasets/aggregate_df.csv
DIR_PROJECT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One
dir_temp=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits/logs
dos2unix ${source}

module purge ; module load anaconda/2.7-4.3.1 afni/v19.0.01
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

##############################################################
### Tranform the Source File So Each Row is an MRI Session ###
##############################################################

awk -F "\"*,\"*" '{print $1,$5,$6}' $source > ${dir_temp}/TEMP_MRI0
awk -F "\"*,\"*" '{print $1,$7,$8}' $source > ${dir_temp}/TEMP_MRI1
awk -F "\"*,\"*" '{print $1,$9,$10}' $source > ${dir_temp}/TEMP_MRI2
awk -F "\"*,\"*" '{print $1,$11,$12}' $source > ${dir_temp}/TEMP_MRI3

sed -i '1d' ls ${dir_temp}/TEMP_MRI[0.1.2.3]
tempfiles=`ls ${dir_temp}/TEMP_MRI[0.1.2.3]`

for ExpectedSessions in $tempfiles ; do
	cat $ExpectedSessions | grep -v ' 0 ' > ${ExpectedSessions}_Reduced.txt
done

for sesnum in {0..3} ; do
	sed s@" 1 "@",${sesnum},"@g ${dir_temp}/TEMP_MRI${sesnum}_Reduced.txt > ${dir_temp}/TEMP_MRI${sesnum}_Reduced_Relabeled.txt
done

cat ${dir_temp}/TEMP_MRI{0..3}_Reduced_Relabeled.txt > ${dir_temp}/TEMP_MRI_Master_Audit.txt

echo 'sub,ses,ScanDate' > ${FINAL_OUTPUT}
cat ${dir_temp}/TEMP_MRI_Master_Audit.txt >> ${FINAL_OUTPUT}
sort -k1 -t ',' -g ${FINAL_OUTPUT} -o	${FINAL_OUTPUT}
rm ${dir_temp}/TEMP_MRI*
dos2unix ${FINAL_OUTPUT}
chmod ug+wrx $FINAL_OUTPUT

#####################################
### Add Behavioral Session Number ###
#####################################

header_og=`head -n1 ${FINAL_OUTPUT}`
header_new=`echo ${header_og},BehVisit`
cat ${FINAL_OUTPUT} | sed s@"${header_og}"@"${header_new}"@g > ${FINAL_OUTPUT}_NEW
mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}

for row in `cat ${FINAL_OUTPUT} | grep -v 'sub' | tr '\n' ' '` ; do
	subid=`echo $row | cut -d ',' -f1`
	session=`echo $row | cut -d ',' -f2`
	dir=`echo 	 /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/dicoms/${subid}_*_${session}`
	Beh=`echo ${dir} | cut -d '_' -f2`
	echo "Behavioral Session is $Beh for Subject: ${subid} Session: ${session}"
	newrow=`echo ${row},${Beh}`
	cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
	mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
done

#######################################################################
### Add Columns Indicating if DICOMS/NIFTIS and PAR/REC Files Exist ###
#######################################################################

header_og=`head -n1 ${FINAL_OUTPUT}`
header_new=`echo ${header_og},Dicoms/Niftis,PARREC`
cat ${FINAL_OUTPUT} | sed s@"${header_og}"@"${header_new}"@g > ${FINAL_OUTPUT}_NEW
mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}

###DICOMS

rows=`cat ${FINAL_OUTPUT} | grep -v 'sub' | tr '\n' ' '`
for row in $rows ; do
	subid=`echo $row | cut -d ',' -f1`
	session=`echo $row | cut -d ',' -f2`

	dir_dicom=`echo 	 /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/dicoms/${subid}_*_${session}/DICOMS`
	dir_nifti=`echo 	 /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/dicoms/${subid}_*_${session}/NIFTIS`
	if [ -d "${dir_dicom}" ] || [ -d "${dir_nifti}" ] ; then
	 echo 'Dicoms Detected For Subject '${subid}' and Session '${session}
	 newrow=`echo ${row},1`
	 cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
	 mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
	else
	 echo 'Dicoms Missing For Subject '${subid}' and Session '${session}
	 newrow=`echo $row,0`
	 cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
	 mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
	fi
done

###PAR/REC 

rows=`cat ${FINAL_OUTPUT} | grep -v 'sub' | tr '\n' ' '`
for row in $rows ; do
	subid=`echo $row | cut -d ',' -f1`
	session=`echo $row | cut -d ',' -f2`
	dir_parrec=`echo /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/dicoms/${subid}_*_${session}/PARREC`
	if [ -d "${dir_parrec}" ]; then
	 echo 'PARREC Files Detected For Subject '${subid}' and Session '${session}
	 newrow=`echo ${row},1`
	 cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
	 mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
	else
	 echo 'PARREC Files Missing For Subject '${subid}' and Session '${session}
	 newrow=`echo $row,0`
	 cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g> ${FINAL_OUTPUT}_NEW
	 mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
	fi
done

############################################################################
### Add Column of Scan Date Based on Dicom Headers to Varify Source File ###
############################################################################

header_og=`head -n1 ${FINAL_OUTPUT}`
header_new=`echo ${header_og},FileDate`
cat ${FINAL_OUTPUT} | sed s@"${header_og}"@"${header_new}"@g > ${FINAL_OUTPUT}_NEW
mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}

rows=`cat ${FINAL_OUTPUT} | grep -v 'sub' | tr '\n' ' '`
for row in $rows ; do
	subid=`echo $row | cut -d ',' -f1`
	session=`echo $row | cut -d ',' -f2`

	dir_dicom=`echo /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/dicoms/${subid}_*_${session}/DICOMS`
	if [ -d "${dir_dicom}" ]; then
	 dcm=`ls 	 /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/dicoms/${subid}_*_${session}/DICOMS/*.dcm | head -n1`
	 header=`dicom_hdr ${dcm} | grep 'ID Study Date'`
	 date=`echo ${header: -8}`
	 newrow=`echo ${row},${date}`
	 cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
	 mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
	 echo 'Scan Completed On '${date}' of Session '${session}' For Subject '${subid}
	else
	 newrow=`echo $row,NA`
	 cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
	 mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
	 echo 'DICOMS Missing For Subject '${subid}' and Session '${session}
	fi
done 

############################################################
### Add Columns Auditing Nifti Files in BIDs Directories ###
############################################################

AuditBIDsData(){
	header_og=`head -n1 ${FINAL_OUTPUT}`
	header_new=`echo ${header_og},${2}`
	cat ${FINAL_OUTPUT} | sed s@"${header_og}"@"${header_new}"@g > ${FINAL_OUTPUT}_NEW
	mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
	rows=`cat ${FINAL_OUTPUT} | grep -v 'sub' | tr '\n' ' '`
	for row in $rows ; do
		subid=`echo $row | cut -d ',' -f1`
		session=`echo $row | cut -d ',' -f2`
		file=`echo /dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/bids/sub-${subid}/ses-${session}/${1}/*${2}*.nii.gz`
		file=`echo $file | cut -d ' ' -f1`
		if [ -f ${file} ] ; then
			newrow=`echo ${row},1`
			cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
			mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
			echo "${1}-${2} NIFTI Detected for Subject ${subid} Session ${session}"
		else
	 		val_dicom=`echo $row | cut -d ',' -f5`
	 		val_parrec=`echo $row | cut -d ',' -f6`
	 		val_ses=`echo $row | cut -d ',' -f2`
	 		if [[ $val_dicom -eq 0 ]] && [[ $val_parrec -eq 0 ]] || [[ $val_ses -eq 0 ]] ; then
				newrow=`echo ${row},NA`
				cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
				mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
				echo "${1}-${2} not expected for Subject ${subid} Session ${session}"
			else
				newrow=`echo ${row},0`
				cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
				mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
				echo "${1}-${2} missing for Subject ${subid} Session ${session}"
			fi
		fi
	done
}

sequences='anat@T1w dwi@dwi func@AMG func@HIPP func@REST_run-01 func@REST_run-02'
for seq in $sequences ; do
	folder=`echo $seq | cut -d '@' -f1`
	name=`echo $seq | cut -d '@' -f2`
	AuditBIDsData $folder $name
done

#########################################################
### Add Columns Auditing the AMG and HIPP Event Files ###
#########################################################

SUBIDS=`cat ${FINAL_OUTPUT} | csvcut -c "sub","ses" | grep -v sub`

header_og=`head -n1 ${FINAL_OUTPUT}`
header_new=`echo ${header_og},AMG_Events,HIPP_Events`
cat ${FINAL_OUTPUT} | sed s@"${header_og}"@"${header_new}"@g > ${FINAL_OUTPUT}_NEW
mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}

for SUBID in $SUBIDS ; do
	SUB=`echo $SUBID | cut -d ',' -f1`
	SES=`echo $SUBID | cut -d ',' -f2`
	unset NIFTI EVENT
	NIFTI=`find $DIR_PROJECT/bids -iname "*AMG*.nii.gz" | grep sub-${SUB}_ses-${SES}`
	EVENT=`find $DIR_PROJECT/bids  -iname "*AMG*.tsv" | grep sub-${SUB}_ses-${SES}`
	if [ -z "${NIFTI}" ] ; then
		echo "Sub-${SUB}_Ses-${SES} Does Not Have Amygdala NIFTI"
		ROW_OLD=$(cat $FINAL_OUTPUT | grep ^$SUB,$SES)
		ROW_NEW=$(echo `cat $FINAL_OUTPUT | grep ^$SUB,$SES`,NA)
	elif [ -z "${EVENT}" ] ; then
		echo "Sub-${SUB}_Ses-${SES} is Missing Amygdala Event File"
		ROW_OLD=$(cat $FINAL_OUTPUT | grep ^$SUB,$SES)
		ROW_NEW=$(echo `cat $FINAL_OUTPUT | grep ^$SUB,$SES`,0)
	else
		echo "Sub-${SUB}_Ses-${SES} Has An Amygdala Event File"
		ROW_OLD=$(cat $FINAL_OUTPUT | grep ^$SUB,$SES)
		ROW_NEW=$(echo `cat $FINAL_OUTPUT | grep ^$SUB,$SES`,1)
	fi
	cat $FINAL_OUTPUT | sed s@"${ROW_OLD}"@${ROW_NEW}@g> ${FINAL_OUTPUT}_NEW
	mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT} ; unset ROW_OLD ROW_NEW
	unset NIFTI_HIPP EVENT_HIPP
	NIFTI_HIPP=`find $DIR_PROJECT/bids -iname "*HIPP*.nii.gz" | grep sub-${SUB}_ses-${SES}`
	EVENT_HIPP=`find $DIR_PROJECT/bids  -iname "*HIPP*.tsv" | grep sub-${SUB}_ses-${SES}`
	if [ -z "${NIFTI_HIPP}" ] ; then
		echo "Sub-${SUB}_Ses-${SES} Does Not Have Hippocampus NIFTI"
		ROW_OLD=$(cat $FINAL_OUTPUT | grep ^$SUB,$SES)
		ROW_NEW=$(echo `cat $FINAL_OUTPUT | grep ^$SUB,$SES`,NA)
	elif [ -z "${EVENT_HIPP}" ] ; then
		echo "Sub-${SUB}_Ses-${SES} is Missing Hippocampus Event File"
		ROW_OLD=$(cat $FINAL_OUTPUT | grep ^$SUB,$SES)
		ROW_NEW=$(echo `cat $FINAL_OUTPUT | grep ^$SUB,$SES`,0)
	else
		echo "Sub-${SUB}_Ses-${SES} Has An Hippocampus Event File"
		ROW_OLD=$(cat $FINAL_OUTPUT | grep ^$SUB,$SES)
		ROW_NEW=$(echo `cat $FINAL_OUTPUT | grep ^$SUB,$SES`,1)
	fi
	cat $FINAL_OUTPUT | sed s@"${ROW_OLD}"@${ROW_NEW}@g> ${FINAL_OUTPUT}_NEW
	mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT} ; unset ROW_OLD ROW_NEW
done

############################################################################
### Add Inclusion Variable Based On Dr. Glynn's Cross-sectional Criteria ###
############################################################################

INCLUDE=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits/rawdata/MRI_Cohort_Scan_Mini_for_MY_Lab.csv
Inclusion_Glynn=`awk -F "\"*,\"*" '{print $1,$2,$3,$4}' ${INCLUDE} | sed s@' '@','@g | sed s@'"'@''@g | tail -n+2`

header_og=`head -n1 ${FINAL_OUTPUT}`
header_new=`echo ${header_og},IntraFlux_Inclusion`
cat ${FINAL_OUTPUT} | sed s@"${header_og}"@"${header_new}"@g > ${FINAL_OUTPUT}_NEW
mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}

INDEX=1
for row in `cat ${FINAL_OUTPUT} | grep -v 'sub' | tr '\n' ' '` ; do
	INDEX=$((INDEX+1))
	sub=`echo $row | cut -d ',' -f1`
	ses=`echo $row | cut -d ',' -f2`
	date=`echo $row | cut -d ',' -f3`
	include=`echo $Inclusion_Glynn | tr ' ' '\n' | grep "^${sub},${ses},${date}"`
	AMG_AUDIT=`cat $FINAL_OUTPUT | csvcut -c AMG | sed -n ${INDEX}p`
	EVENT_AUDIT=`cat $FINAL_OUTPUT | csvcut -c AMG_Events | sed -n ${INDEX}p`
	REST1_AUDIT=`cat $FINAL_OUTPUT | csvcut -c REST_run-01 | sed -n ${INDEX}p`
	REST2_AUDIT=`cat $FINAL_OUTPUT | csvcut -c REST_run-02 | sed -n ${INDEX}p`
	if [[ ! -z $include && ${AMG_AUDIT} == 1 && ${EVENT_AUDIT} == 1 && ${REST1_AUDIT} == 1 && ${REST2_AUDIT} == 1  && ${sub} != '7008' ]] ; then
		newrow=`echo $row,1`
		cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
		echo "Including Into Cross-Sectional Sample subject: $sub ses: $ses"
	else
		newrow=`echo ${row},0`
		cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
		echo "Excluding From Cross-Sectional Sample subject: $sub ses: $ses"
	fi
	mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
done

###################################
### Add Demographic Information ###
###################################

DEMO=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/datasets/predictors/n424_Age+Sex_20200320.csv
Demo_GoogleDrive=`awk -F "\"*,\"*" '{print $1,$2,$3,$4}' ${DEMO} | sed s@' '@','@g | sed s@'"'@''@g | tail -n+2`

header_og=`head -n1 ${FINAL_OUTPUT}`
header_new=`echo ${header_og},AgeAtScan,Gender`
cat ${FINAL_OUTPUT} | sed s@"${header_og}"@"${header_new}"@g > ${FINAL_OUTPUT}_NEW
mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}

for row in `cat ${FINAL_OUTPUT} | grep -v 'sub' | tr '\n' ' '` ; do
	sub=`echo $row | cut -d ',' -f1`
	ses=`echo $row | cut -d ',' -f2`
	demo=`echo $Demo_GoogleDrive |	tr ' ' '\n' | grep "^${sub},${ses}," | cut -d ' ' -f1 | cut -d ',' -f3,4`
	echo ""
	echo "subject: $sub session: $ses demo: $demo"
	if [ -z $demo ] ; then
		newrow=`echo $row,NA,NA`
		cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
		mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
		echo "Demographic Data MISSING for subject: $sub ses: $ses"
	else
		newrow=`echo ${row},${demo}`
		cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
		mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
		echo "Demographic Data Added for subject: $sub ses: $ses"
	fi
done

#####################################################################
### Add Demographic and Clinical Data Sent From Laura on 20200617 ###
#####################################################################

DEMO=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One/audits/rawdata/MRI_Cohort_Predictors_for_MY_Lab.csv
DEMO_CONTENT=`awk -F "\"*,\"*" '{print $1,$2,$7,$5,$6,$8}' ${DEMO} | sed s@' '@','@g | tail -n +2`

header_og=`head -n1 ${FINAL_OUTPUT}`
header_new=`echo ${header_og},AgeAtBeh,PreMood_Ent,PreMood_Lvl,scl-CDI_MD`
cat ${FINAL_OUTPUT} | sed s@"${header_og}"@"${header_new}"@g > ${FINAL_OUTPUT}_NEW
mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}

for row in `cat ${FINAL_OUTPUT} | grep -v 'sub' | tr '\n' ' '` ; do
	sub=`echo $row | cut -d ',' -f1`
	ses=`echo $row | cut -d ',' -f2`
	demo=`echo $DEMO_CONTENT |tr ' ' '\n' | grep "^${sub},${ses}," | sed s@"${sub},${ses},"@@g`
	echo ""
	echo "subject: $sub session: $ses demo: $demo"
	if [ -z $demo ] ; then
		newrow=`echo $row,NA,NA,NA,NA`
		cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
		mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
		echo "Predictor Data MISSING for subject: $sub ses: $ses"
	else
		newrow=`echo ${row},${demo}`
		cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
		mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
		echo "Predictor Data Added for subject: $sub ses: $ses"
	fi
done


echo "Master File Created Successfully"
chmod ug+wrx $FINAL_OUTPUT
exit 

############################################
### Add Audit of DBK Freesurfer Analysis ###
############################################
<<SKIP_NOT_NEEDED_ANYMORE
Freesurfer_DBK='/dfs2/yassalab/rjirsara/ConteCenter/Datasets/Conte-One/T1w/20190909/n362_APARC+ASEG_20190909.csv'

header_og=`head -n1 ${FINAL_OUTPUT}`
header_new=`echo ${header_og},Freesurfer_DBK`
cat ${FINAL_OUTPUT} | sed s@"${header_og}"@"${header_new}"@g > ${FINAL_OUTPUT}_NEW
mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}

rows=`cat ${FINAL_OUTPUT} | grep -v 'sub' | tr '\n' ' '`
for row in $rows ; do
	sub=`echo $row | cut -d ',' -f1`
	ses=`echo $row | cut -d ',' -f2`
	BIDS_T1w=`echo $row | cut -d ',' -f8`
	oldrow=`cat $Freesurfer_DBK | grep "^${sub},${ses}," | cut -d ' ' -f1`
	echo 
	echo subject: $sub session: $ses bids: $BIDS_T1w
	
	if [ -z $oldrow ] ; then
	 if [ $BIDS_T1w == 1 ] ; then
		newrow=`echo $row,0`
		cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
		mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
		echo "0: Scan not Found but was Expected for Subject: ${sub} Session: ${ses}"
		else
	 	newrow=`echo $row,NA`
	 	cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
	 	mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
	 	echo "NA: Scan not Found and Not Expected for Subject: ${sub} Session: ${ses}"
	 fi
	else
 	if [ $BIDS_T1w == 1 ] ; then
	 	newrow=`echo $row,1`
	 	cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
	 	mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
	 	echo "1: Scan Found and Expected for Subject: ${sub} Session: ${ses}"
	 else
	 	newrow=`echo $row,999`
	 	cat ${FINAL_OUTPUT} | sed s@"${row}"@"${newrow}"@g > ${FINAL_OUTPUT}_NEW
	 	mv ${FINAL_OUTPUT}_NEW ${FINAL_OUTPUT}
	 	echo "999 Scan Found But Was Not Expected: ${sub} Session: ${ses}"
	fi
	fi
done
SKIP_NOT_NEEDED_ANYMORE
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

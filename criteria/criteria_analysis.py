# read all the file from path: /mnt/dell_storage/labs/NPC/DataSink/StimTool_Online/WB_Advice

import os
import pandas as pd
files = os.listdir('/mnt/dell_storage/labs/NPC/DataSink/StimTool_Online/WB_Advice')

# read csv file contain all the subject ids
subject_list_path = '/mnt/dell_storage/labs/rsmith/lab-members/fli/advise_task/subject_id/advise_subject_IDs_prolific_wo_uncomplete.csv'


subjects = []
with open(subject_list_path) as infile:
    for line in infile:
        if 'ID' not in line:
            subjects.append(line.strip())

# read each file of subject, the file named "active_trust_[subject_id]_T[1,2,3]_2024-07-25-02h29.56.847.csv"
# for each subject always read the latest and complete file
subject_files = {}
for subject in subjects:
    # find all the files name in the format "active_trust_[subject_id]_T[1,2,3]_2024-07-25-02h29.56.847.csv"
    temp_list = []
    for file in files:
        if file.startswith('active_trust_'+subject+'_T') and file.endswith('.csv'):
            temp_list.append(file)
    if len(temp_list) == 1:
        subject_files[subject] = temp_list[0]
    elif len(temp_list) > 1:
        print('Multiple files for subject:', subject)
        # sort the files by date
        temp_list.sort()
        print('Files:', temp_list)
        for current_file in temp_list:
            # read as pd dataframe
            cur_pd = pd.read_csv('/mnt/dell_storage/labs/NPC/DataSink/StimTool_Online/WB_Advice/'+current_file)
            # check if the file is complete by end row trail is 359
            if cur_pd.iloc[-1]['trial'] == 359:
                subject_files[subject] = current_file
            else:
                print('File is not complete:', current_file)
    else:
        print('No file for subject:', subject)

print(f"Read {len(subject_files)} files")






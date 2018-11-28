# search for a list in another list
sr_list = ['a']
file_var=''
import re
fin_lst=[]
substitutions = {'Info :  ':'','\n':''}
def replace(string, substitutions):
    substrings = sorted(substitutions, key=len, reverse=True)
    regex = re.compile('|'.join(map(re.escape, substrings)))
    return regex.sub(lambda match: substitutions[match.group(0)], string)
with open(file_var) as fp:
           for line in fp:
                #print(line)
                if 'Processing' in line:
                    #fin_lst.append(line)
                    line1 = replace(line, substitutions)
                    fin_lst.append(line1)
                    

#print(fin_lst)
#for name in sr_list:
#    if name in 
result =  all(elem in fin_lst  for elem in sr_list)
#if result:
#    print("Yes, list1 contains all elements in list2")    
#else :
#    print("No, list1 does not contains all elements in list2")
print("Additional values in First list:",list((set(sr_list).difference(fin_lst))))

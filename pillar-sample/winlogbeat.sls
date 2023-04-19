#
## winlogbeat.sls - 
#
## (c) ecgf - junho/2021
#

#
## eventos que têm alta frequência e baixa utilidade
Security: 
  event_id: '4264-5144, -4656, -4658, -4690, -5152'
System:
  event_id: '0-20000, -7036, -1'

# 
## define eventids por tipo de servidor.
events_not_dropped:
  #
  # eventos que todos os servidores enviarão
  # 4624 - logon success
  # 4625 - logon failed
  # 4634 - logoff
  # 4648 - logon as other user
  # 4775 - ntlm account could not be mapped to logon
  # 4777 - ntlm account failed to validate credentials at DC
  #
  general:
    eventid:
      - 4264
      - 4625
      - 4634
      - 4648
      - 4775
      - 4777
  
  #
  # eventos de file server. ACL Change e File Access
  # file access:
  # 4660 - file deleted
  # 4663 - attempt to access a file
  # 4664 - hard link created
  # permissions changed:
  # 4670 - permissions changed
  # network shares:
  # 5140 - network share accessed
  # 5142 - network share added
  # 5143 - network share modified
  # 5144 - network share deleted
  fileserver:
    eventid:
      - 4660
      - 4663
      - 4664
      - 4670
      - 5140
      - 5142
      - 5143
      - 5144
  
  #
  # eventos de Active Directory. Gerenciamento de usuários/grupos e GPO
  # Grupos:
  # 4764 - alteração no tipo de grupo
  # 4727 - security global group created
  # 4737 - security global group changed
  # 4728 - member added to security global group
  # 4729 - member removed from security global group
  # 4730 - security global group deleted
  # 4754 - security universal group created
  # 4755 - security universal group changed
  # 4756 - member added to security universal group
  # 4757 - member removed from security universal group
  # 4758 - security universal group deleted
  # Computers:
  # 4741 - computer account created
  # 4742 - computer account changed
  # 4743 - computer account deleted
  # Users:
  # 4720 - user account created
  # 4722 - user account enabled
  # 4725 - user account disabled
  # 4726 - user account deleted
  # 4738 - user account changed
  # 4740 - user account locked out
  # 4767 - user account unlock
  # 4781 - user account name changed
  # Other:
  # 4649 - replay attack detected
  activedirectory:
    eventid:
      - 4764
      - 4727
      - 4737
      - 4728
      - 4729
      - 4730
      - 4754
      - 4755
      - 4756
      - 4757
      - 4758
      - 4741
      - 4742
      - 4743
      - 4720
      - 4722
      - 4725
      - 4726
      - 4738
      - 4740
      - 4767
      - 4781
      - 4649
      
events_dropped:
  general:
    eventid:
      - 7036

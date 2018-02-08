<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
 <fullName>TechnicalQualityTeam__c</fullName>
 <rules>
  <fullName>Notify TQT of Role</fullName>
  <actions>
   <name>Send_TQT_Notification</name>
   <type>Alert</type>
  </actions>
  <actions>
   <name>Update_Send_Email</name>
   <type>FieldUpdate</type>
  </actions>
  <actions>
   <name>Update_Sent_Email</name>
   <type>FieldUpdate</type>
  </actions>
  <active>false</active>
  <criteriaItems>
   <field>TechnicalQualityTeam__c.SendEmail__c</field>
   <operation>equals</operation>
   <value>True</value>
  </criteriaItems>
  <criteriaItems>
   <field>TechnicalQualityTeam__c.Role__c</field>
   <operation>notEqual</operation>
   <value>Deliverable Originator</value>
  </criteriaItems>
  <triggerType>onAllChanges</triggerType>
 </rules>
</Workflow>

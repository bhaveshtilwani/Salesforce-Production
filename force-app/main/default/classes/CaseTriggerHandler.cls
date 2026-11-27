public class CaseTriggerHandler {

    public static void updateProductLine(List<Case> caseList) {
        for (Case cs : caseList) {
            if (cs.Origin == 'Email'
                && cs.Subject != null
                && cs.Subject.contains('Product Price Update')
                && cs.Description != null) {
					
                String descriptionText = cs.Description;

                

                Pattern p1 = Pattern.compile(
                    '(?im)^\\s*Product Line\\s*:\\s*(.+?)\\s*$'
                );
                Matcher m1 = p1.matcher(descriptionText);
                if (m1.find()) {
                    cs.Product_Line_Text__c = m1.group(1).trim();
                }

                Pattern p2 = Pattern.compile(
                    '(?im)^\\s*Sub Family\\s*:\\s*(.+?)\\s*$'
                );
                Matcher m2 = p2.matcher(descriptionText);
                if (m2.find()) {
                    cs.Product_sub_Family_Text__c = m2.group(1).trim();
                }
				/*
                Pattern p3 = Pattern.compile(
                    '(?im)^\\s*Primary Product Division\\s*:\\s*(.+?)\\s*$'
                );
                Matcher m3 = p3.matcher(descriptionText);
                if (m3.find()) {
                    cs.Primary_Product_Division__c = m3.group(1).trim();
                }

                Pattern p4 = Pattern.compile(
                    '(?im)^\\s*Primary Sub Family\\s*:\\s*(.+?)\\s*$'
                );
                Matcher m4 = p4.matcher(descriptionText);
                if (m4.find()) {
                    cs.Primary_Sub_Family__c = m4.group(1).trim();
                }

                Pattern p5 = Pattern.compile(
                    '(?im)^\\s*Business Unit\\s*:\\s*(.+?)\\s*$'
                );
                Matcher m5 = p5.matcher(descriptionText);
                if (m5.find()) {
                    cs.Business_Unit__c = m5.group(1).trim();
                }
*/
            }
        }
    }
}
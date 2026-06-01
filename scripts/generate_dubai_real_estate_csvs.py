from __future__ import annotations

import csv
import re
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(r"c:\Users\shubham.yadav_infobe\Desktop\ALL Migration\ALL Migratation")
OBJECTS_DIR = ROOT / "force-app" / "main" / "default" / "objects"
OUTPUT_DIR = ROOT / "scripts" / "data" / "dubai-real-estate"

NS = {"m": "http://soap.sforce.com/2006/04/metadata"}


@dataclass(frozen=True)
class ObjectSpec:
    api_name: str
    records: list[dict[str, str]]
    external_key_field: str | None


OBJECT_SPECS: list[ObjectSpec] = [
    ObjectSpec(
        api_name="VAT__c",
        external_key_field="Retained_Id__c",
        records=[
            {
                "Name": "Dubai VAT 5 Percent",
                "Retained_Id__c": "VAT-DXB-005",
                "Vat__c": "5",
                "VAT_Transaction__c": "Dubai residential inventory VAT standard rate",
                "VAT_GL_Account__c": "VAT GL account for Dubai real estate",
                "Is_Active__c": "true",
            }
        ],
    ),
    ObjectSpec(
        api_name="AR_GL_Account__c",
        external_key_field="Yardi_GlCode__c",
        records=[
            {
                "Name__c": "Dubai Receivables GL",
                "Yardi_GlCode__c": "GL-10001",
                "Retained_Id__c": "ARGL-DXB-001",
                "Source_System__c": "Dubai Real Estate Seed",
                "GL_Type__c": "Revenue",
                "GL_Type_Description__c": "Revenue account for Dubai residential inventory",
                "Fusion_Code__c": "FUS-GL-10001",
                "Category__c": "Dubai",
                "Balance__c": "0",
                "Debit__c": "0",
                "Credit__c": "0",
                "Ending_Balance__c": "0",
                "Legal_Entity__c": "Meraas",
            }
        ],
    ),
    ObjectSpec(
        api_name="AR_Legal_Entity__c",
        external_key_field="EBS_Segment_1__c",
        records=[
            {
                "Name": "Dubai Development Legal Entity",
                "EBS_Segment_1__c": "ARLE-DXB-001",
                "Full_Legal_Name_of_Entity__c": "Dubai Land Development LLC",
                "Source_System__c": "Dubai Real Estate Seed",
                "VAT_Group__c": "Dubai VAT Group A",
                "Tax_Registration_Number__c": "TRN-100200300",
                "Tax_Registered__c": "true",
                "Registered_Address__c": "Downtown Dubai, Dubai, UAE",
                "Operating_Unit__c": "Dubai",
                "Email_address__c": "legal.entity@dubai-real-estate.example",
                "GL_Segment_1__c": "DXB-LE-001",
                "Invoice_Total_Unpaid_Amount__c": "0",
                "Invoice_Total_Paid_Amount__c": "0",
                "FA_GL_Account__c": "GL-10001",
            }
        ],
    ),
    ObjectSpec(
        api_name="AR_Bank_Account__c",
        external_key_field="EBS_Bank_Account_ID__c",
        records=[
            {
                "Name": "Dubai Escrow Bank Account",
                "EBS_Bank_Account_ID__c": "ARBANK-DXB-001",
                "Retained_Id__c": "ARBANK-RET-001",
                "Source_System__c": "Dubai Real Estate Seed",
                "Swift_Code__c": "DUBAIEFX",
                "Project_Bank_Type__c": "Escrow",
                "Merchant_Name__c": "Dubai Escrow Merchant",
                "Merchant_Id__c": "MCH-DXB-001",
                "Legal_Entity__c": "Dubai Development Legal Entity",
                "Is_DHLE__c": "true",
                "Project_Code__c": "DXB-PRJ-001",
                "Project_Property_Code__c": "DXB-PRJ-001-P1",
                "Project__r.Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB",
                "Property__r.Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB_RES_A",
            }
        ],
    ),
    ObjectSpec(
        api_name="Floor_Plan__c",
        external_key_field=None,
        records=[
            {
                "Name": "Skyline Heights 1 Bed Floor Plan",
                "Typology__c": "1 BED",
                "Project__r.Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB",
                "File_Name__c": "skyline-heights-1-bed-floor-plan.pdf",
                "File_Name_Furniture__c": "skyline-heights-1-bed-furniture-plan.pdf",
                "Building__c": "Tower A",
            }
        ],
    ),
    ObjectSpec(
        api_name="Project__c",
        external_key_field="Unique_External_Key__c",
        records=[
            {
                "Name": "Skyline Heights",
                "Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB",
                "Project_Name__c": "Skyline Heights",
                "Project_Name_Arabic__c": "سكاي لاين هايتس",
                "Project_Code__c": "DXB-SKY-001",
                "Project_Code_Ar__c": "DXB-SKY-AR-001",
                "Project_Status__c": "Green",
                "Project_Type__c": "Off Plan",
                "Size_Type__c": "3 BHK",
                "Active__c": "true",
                "Company__c": "Meraas",
                "City__c": "Dubai",
                "Locality_Name__c": "Dubai Marina",
                "Township_Name__c": "Marina District",
                "Master_Community__c": "Dubai Marina",
                "Master_Community_Arabic__c": "دبي مارينا",
                "Site_Name__c": "Skyline Heights Marina Site",
                "Project_Location__c": "25.0800,55.1400",
                "Project_Address__c": "Dubai Marina, Dubai, UAE",
                "Project_Description__c": "Premium waterfront tower development overlooking Dubai Marina.",
                "Project_Image__c": "https://images.example.com/dubai/skyline-heights.jpg",
                "Project_Header__c": "Skyline Heights Overview",
                "Amenity_Header__c": "Skyline Heights Amenities",
                "Proximity_Header__c": "Nearby Dubai Marina Landmarks",
                "Specification_Header__c": "Skyline Heights Specifications",
                "Visible_to_Portal_Users__c": "true",
                "Show_In_Manage_Inventory__c": "true",
                "VAT_Applicable__c": "true",
                "Target_DLD_Value__c": "550000000",
                "Actual_DLD_Value__c": "520000000",
                "Balance_DLD__c": "30000000",
                "Total_Units__c": "120",
                "Total_Units_Sold__c": "36",
                "Total_Units_Available__c": "84",
                "Total_Towers__c": "2",
                "Parking_Included_per_unit__c": "2",
                "Project_Manager__c": "Dubai Project Team",
                "Project_Completion_Date__c": "2027-12-31",
                "Current_anticipated_handover_date__c": "2027-10-31",
                "Phase_Date__c": "2026-09-30",
                "BTS_ANTICIPATED_HANDOVER_DATE__c": "2027-10-31",
                "BTS_TOTAL_AREA_SQFT__c": "850000",
                "Resvered_GFA__c": "15000",
                "GFA_Rate__c": "965",
                "ProfitCenter__c": "DXB-MARINA",
                "PO_BOX__c": "12345",
                "PO_BOX_AR__c": "١٢٣٤٥",
                "Seller_Name__c": "Dubai Holdings",
                "Seller_Name_Arabic__c": "دبي هولدينجز",
                "Seller_P_O_Box__c": "12345",
                "Seller_P_O_Box_Arabic__c": "١٢٣٤٥",
                "Seller_Registration_No__c": "SRN-2026-001",
                "Seller_Registration_No_Arabic__c": "SRN-AR-2026-001",
                "Ownership_Type__c": "Freehold",
                "Ownership_Sub_Category__c": "Residential",
                "Property_Name_BF_SPA__c": "Skyline Heights Residence SPA",
                "Property_Name_BF_SPA_AR__c": "سكاي لاين هايتس SPA",
                "Property_Name_BF__c": "Skyline Heights",
                "Retained_Id__c": "PRJ-RET-001",
                "ERP_Project_Id__c": "ERP-PRJ-001",
                "SAP_Project_Unique__c": "SAP-PRJ-001",
                "SAP_Project_No__c": "SAP10001",
                "Oracle_Project_ID__c": "ORCL-PRJ-001",
                "MiscBankUnique__c": "MBU-PRJ-001",
                "InvoiceBankUnique__c": "INV-PRJ-001",
                "CreditBankUnique__c": "CRD-PRJ-001",
                "Legal_Entity__c": "Dubai Development Legal Entity",
                "Legal_Entity_Name__c": "Dubai Development Legal Entity",
                "Legal_Entity_Code__c": "LE-DXB-001",
                "Legal_Entity_Arabic__c": "كيان قانوني دبي",
                "Business_Unit__c": "Residential",
                "Classification_Type__c": "Residential",
                "Company_Code__c": "MERAAS",
                "Financial_Account__c": "FA-DXB-001",
                "Notes__c": "Dubai marina flagship project seed data.",
                "Terms_and_Conditions__c": "Standard Dubai residential sale terms apply.",
                "Description__c": "Complete Dubai-themed project master data for import testing.",
                "Project_18_Digit_ID__c": "001XX0000000001AAA",
                "Project_Image__c": "https://images.example.com/dubai/skyline-heights.jpg",
                "Bank_GL__r.Yardi_GlCode__c": "GL-10001",
                "Default_VAT_Lookup__r.Retained_Id__c": "VAT-DXB-005",
                "Default_Escrow_Bank_Account__r.EBS_Bank_Account_ID__c": "ARBANK-DXB-001",
                "Legal_Entity_CL__r.EBS_Segment_1__c": "ARLE-DXB-001",
                "Legal_Entity_DHLE__r.EBS_Segment_1__c": "ARLE-DXB-001",
                "Notes_Receivables_GL__r.Yardi_GlCode__c": "GL-10001",
            },
            {
                "Name": "Damac Lagoons",
                "Unique_External_Key__c": "DAMAC_LAGOONS_DXB",
                "Project_Name__c": "Damac Lagoons",
                "Project_Name_Arabic__c": "داماك لاجونز",
                "Project_Code__c": "DXB-DAM-001",
                "Project_Code_Ar__c": "DXB-DAM-AR-001",
                "Project_Status__c": "Green",
                "Project_Type__c": "Ready",
                "Size_Type__c": "Villa",
                "Active__c": "true",
                "Company__c": "Nakheel",
                "City__c": "Dubai",
                "Locality_Name__c": "Dubai Land",
                "Township_Name__c": "Damac Lagoons",
                "Master_Community__c": "Damac Lagoons",
                "Master_Community_Arabic__c": "داماك لاجونز",
                "Site_Name__c": "Damac Lagoons Community",
                "Project_Location__c": "25.0350,55.2900",
                "Project_Address__c": "Damac Lagoons, Dubai, UAE",
                "Project_Description__c": "Waterfront villa and townhouse community inspired by lagoon living.",
                "Project_Image__c": "https://images.example.com/dubai/damac-lagoons.jpg",
                "Project_Header__c": "Damac Lagoons Overview",
                "Amenity_Header__c": "Damac Lagoons Amenities",
                "Proximity_Header__c": "Nearby Dubai Land Landmarks",
                "Specification_Header__c": "Damac Lagoons Specifications",
                "Visible_to_Portal_Users__c": "true",
                "Show_In_Manage_Inventory__c": "true",
                "VAT_Applicable__c": "true",
                "Target_DLD_Value__c": "475000000",
                "Actual_DLD_Value__c": "455000000",
                "Balance_DLD__c": "20000000",
                "Total_Units__c": "96",
                "Total_Units_Sold__c": "28",
                "Total_Units_Available__c": "68",
                "Total_Towers__c": "4",
                "Parking_Included_per_unit__c": "1",
                "Project_Manager__c": "Dubai Project Team",
                "Project_Completion_Date__c": "2026-12-31",
                "Current_anticipated_handover_date__c": "2026-10-31",
                "Phase_Date__c": "2026-06-30",
                "BTS_ANTICIPATED_HANDOVER_DATE__c": "2026-10-31",
                "BTS_TOTAL_AREA_SQFT__c": "690000",
                "Resvered_GFA__c": "12000",
                "GFA_Rate__c": "890",
                "ProfitCenter__c": "DXB-DL",
                "PO_BOX__c": "22334",
                "PO_BOX_AR__c": "٢٢٣٣٤",
                "Seller_Name__c": "Damac Properties",
                "Seller_Name_Arabic__c": "داماك العقارية",
                "Seller_P_O_Box__c": "22334",
                "Seller_P_O_Box_Arabic__c": "٢٢٣٣٤",
                "Seller_Registration_No__c": "SRN-2026-002",
                "Seller_Registration_No_Arabic__c": "SRN-AR-2026-002",
                "Ownership_Type__c": "Freehold",
                "Ownership_Sub_Category__c": "Residential",
                "Property_Name_BF_SPA__c": "Damac Lagoons SPA",
                "Property_Name_BF_SPA_AR__c": "داماك لاجونز SPA",
                "Property_Name_BF__c": "Damac Lagoons",
                "Retained_Id__c": "PRJ-RET-002",
                "ERP_Project_Id__c": "ERP-PRJ-002",
                "SAP_Project_Unique__c": "SAP-PRJ-002",
                "SAP_Project_No__c": "SAP10002",
                "Oracle_Project_ID__c": "ORCL-PRJ-002",
                "MiscBankUnique__c": "MBU-PRJ-002",
                "InvoiceBankUnique__c": "INV-PRJ-002",
                "CreditBankUnique__c": "CRD-PRJ-002",
                "Legal_Entity__c": "Dubai Development Legal Entity",
                "Legal_Entity_Name__c": "Dubai Development Legal Entity",
                "Legal_Entity_Code__c": "LE-DXB-001",
                "Legal_Entity_Arabic__c": "كيان قانوني دبي",
                "Business_Unit__c": "Residential",
                "Classification_Type__c": "Residential",
                "Company_Code__c": "NAKHEEL",
                "Financial_Account__c": "FA-DXB-002",
                "Notes__c": "Dubai lagoon community seed data.",
                "Terms_and_Conditions__c": "Standard Dubai residential sale terms apply.",
                "Description__c": "Complete Dubai-themed project master data for import testing.",
                "Project_18_Digit_ID__c": "001XX0000000002AAA",
                "Bank_GL__r.Yardi_GlCode__c": "GL-10001",
                "Default_VAT_Lookup__r.Retained_Id__c": "VAT-DXB-005",
                "Default_Escrow_Bank_Account__r.EBS_Bank_Account_ID__c": "ARBANK-DXB-001",
                "Legal_Entity_CL__r.EBS_Segment_1__c": "ARLE-DXB-001",
                "Legal_Entity_DHLE__r.EBS_Segment_1__c": "ARLE-DXB-001",
                "Notes_Receivables_GL__r.Yardi_GlCode__c": "GL-10001",
            },
        ],
    ),
    ObjectSpec(
        api_name="Property__c",
        external_key_field="Unique_External_Key__c",
        records=[
            {
                "Name": "Skyline Heights Residences A",
                "Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB_RES_A",
                "Project_Inv__r.Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB",
                "Property_Name_BF__c": "Skyline Heights Residences A",
                "Property_Name_BF_SPA__c": "Skyline Heights Residences A SPA",
                "Property_Name_BF_SPA_AR__c": "سكاي لاين هايتس ريزيدنسز A",
                "Property_Name_Arabic__c": "سكاي لاين هايتس ريزيدنسز A",
                "Property_Name_BF_Ar__c": "سكاي لاين هايتس ريزيدنسز A",
                "Property_Type__c": "Luxury",
                "Type_of_Property__c": "Apartment",
                "Project_Type__c": "Off Plan",
                "Project_Name_Report__c": "Skyline Heights",
                "Project_18_Digit_ID__c": "001XX0000000001AAA",
                "Project_Code__c": "DXB-SKY-001",
                "Project_Code_Ar__c": "DXB-SKY-AR-001",
                "Project_Name_in_Arabic__c": "سكاي لاين هايتس",
                "Project_Name__c": "Skyline Heights",
                "Project_Name_Report__c": "Skyline Heights",
                "Project__r.Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB",
                "Building_Name__c": "Skyline Heights Tower A",
                "Building_Name_Arabic__c": "برج سكاي لاين هايتس A",
                "DLD_Area_Name__c": "Dubai Marina",
                "Master_Community__c": "Dubai Marina",
                "Master_Community_Arabic__c": "دبي مارينا",
                "Terrace__c": "true",
                "Allotted_Parking__c": "2",
                "Alloted_storage__c": "1",
                "Launch_Date__c": "2026-01-15",
                "Current_anticipated_handover_date__c": "2027-10-31",
                "BTS_ANTICIPATED_HANDOVER_DATE__c": "2027-10-31",
                "Handover_Percentage__c": "40",
                "DHRE_Construction_Percent__c": "55",
                "RERA_Construction_Percent__c": "53",
                "RERA_Updated__c": "true",
                "Rera_Inspection_Date__c": "2026-05-01",
                "Disclosure_Statement_Pages_Count__c": "24",
                "Is_Disclosure_Statement_Available__c": "true",
                "Construction_Update_Sent__c": "true",
                "Construction_Updates_Link__c": "https://updates.example.com/skyline-heights",
                "Approved_By_Finance__c": "true",
                "Exclu...__c": "false",
                "Notes__c": "Dubai Marina residential property seed data.",
                "Description__c": "Full property master data for Skyline Heights Residences A.",
                "Company__c": "Meraas",
                "Legal_Entity__c": "Dubai Development Legal Entity",
                "Project_Type__c": "Off Plan",
                "PropertyCode__c": "PROP-SKY-A",
                "Property_ID_18__c": "003XX0000000001AAA",
                "ERP_Property_Id__c": "ERP-PROP-001",
                "ERP_Property_Code__c": "ERP-PROP-CODE-001",
                "DLD_Property_Id__c": "DLD-PROP-001",
                "Retained_Id__c": "PROP-RET-001",
                "Thw_Property_Code__c": "THW-PROP-001",
                "Property_Inv__c": "",
                "VAT__r.Retained_Id__c": "VAT-DXB-005",
                "Bank_GL__r.Yardi_GlCode__c": "GL-10001",
                "Default_Bank_Account__r.EBS_Bank_Account_ID__c": "ARBANK-DXB-001",
                "Notes_Receivables_GL__r.Yardi_GlCode__c": "GL-10001",
                "Active__c": "true",
            },
            {
                "Name": "Skyline Heights Residences B",
                "Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB_RES_B",
                "Project_Inv__r.Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB",
                "Property_Name_BF__c": "Skyline Heights Residences B",
                "Property_Name_BF_SPA__c": "Skyline Heights Residences B SPA",
                "Property_Name_BF_SPA_AR__c": "سكاي لاين هايتس ريزيدنسز B",
                "Property_Name_Arabic__c": "سكاي لاين هايتس ريزيدنسز B",
                "Property_Name_BF_Ar__c": "سكاي لاين هايتس ريزيدنسز B",
                "Property_Type__c": "Normal",
                "Type_of_Property__c": "Apartment",
                "Project_Type__c": "Off Plan",
                "Project_Name_Report__c": "Skyline Heights",
                "Project_18_Digit_ID__c": "001XX0000000001AAA",
                "Project_Code__c": "DXB-SKY-001",
                "Project_Code_Ar__c": "DXB-SKY-AR-001",
                "Project_Name_in_Arabic__c": "سكاي لاين هايتس",
                "Project_Name__c": "Skyline Heights",
                "Project_Name_Report__c": "Skyline Heights",
                "Project__r.Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB",
                "Building_Name__c": "Skyline Heights Tower B",
                "Building_Name_Arabic__c": "برج سكاي لاين هايتس B",
                "DLD_Area_Name__c": "Dubai Marina",
                "Master_Community__c": "Dubai Marina",
                "Master_Community_Arabic__c": "دبي مارينا",
                "Terrace__c": "true",
                "Allotted_Parking__c": "1",
                "Alloted_storage__c": "1",
                "Launch_Date__c": "2026-01-15",
                "Current_anticipated_handover_date__c": "2027-10-31",
                "BTS_ANTICIPATED_HANDOVER_DATE__c": "2027-10-31",
                "Handover_Percentage__c": "40",
                "DHRE_Construction_Percent__c": "55",
                "RERA_Construction_Percent__c": "53",
                "RERA_Updated__c": "true",
                "Rera_Inspection_Date__c": "2026-05-01",
                "Disclosure_Statement_Pages_Count__c": "22",
                "Is_Disclosure_Statement_Available__c": "true",
                "Construction_Update_Sent__c": "true",
                "Construction_Updates_Link__c": "https://updates.example.com/skyline-heights-b",
                "Approved_By_Finance__c": "true",
                "Notes__c": "Dubai Marina residential property seed data.",
                "Description__c": "Full property master data for Skyline Heights Residences B.",
                "Company__c": "Meraas",
                "Legal_Entity__c": "Dubai Development Legal Entity",
                "Project_Type__c": "Off Plan",
                "PropertyCode__c": "PROP-SKY-B",
                "Property_ID_18__c": "003XX0000000002AAA",
                "ERP_Property_Id__c": "ERP-PROP-002",
                "ERP_Property_Code__c": "ERP-PROP-CODE-002",
                "DLD_Property_Id__c": "DLD-PROP-002",
                "Retained_Id__c": "PROP-RET-002",
                "Thw_Property_Code__c": "THW-PROP-002",
                "VAT__r.Retained_Id__c": "VAT-DXB-005",
                "Bank_GL__r.Yardi_GlCode__c": "GL-10001",
                "Default_Bank_Account__r.EBS_Bank_Account_ID__c": "ARBANK-DXB-001",
                "Notes_Receivables_GL__r.Yardi_GlCode__c": "GL-10001",
                "Active__c": "true",
            },
            {
                "Name": "Damac Lagoons Residences A",
                "Unique_External_Key__c": "DAMAC_LAGOONS_DXB_RES_A",
                "Project_Inv__r.Unique_External_Key__c": "DAMAC_LAGOONS_DXB",
                "Property_Name_BF__c": "Damac Lagoons Residences A",
                "Property_Name_BF_SPA__c": "Damac Lagoons Residences A SPA",
                "Property_Name_BF_SPA_AR__c": "داماك لاجونز ريزيدنسز A",
                "Property_Name_Arabic__c": "داماك لاجونز ريزيدنسز A",
                "Property_Name_BF_Ar__c": "داماك لاجونز ريزيدنسز A",
                "Property_Type__c": "Luxury",
                "Type_of_Property__c": "Villa",
                "Project_Type__c": "Ready",
                "Project_Name_Report__c": "Damac Lagoons",
                "Project_18_Digit_ID__c": "001XX0000000002AAA",
                "Project_Code__c": "DXB-DAM-001",
                "Project_Code_Ar__c": "DXB-DAM-AR-001",
                "Project_Name_in_Arabic__c": "داماك لاجونز",
                "Project_Name__c": "Damac Lagoons",
                "Project_Name_Report__c": "Damac Lagoons",
                "Project__r.Unique_External_Key__c": "DAMAC_LAGOONS_DXB",
                "Building_Name__c": "Damac Lagoons Villa Cluster A",
                "Building_Name_Arabic__c": "داماك لاجونز فيلا A",
                "DLD_Area_Name__c": "Dubai Land",
                "Master_Community__c": "Damac Lagoons",
                "Master_Community_Arabic__c": "داماك لاجونز",
                "Terrace__c": "true",
                "Allotted_Parking__c": "2",
                "Alloted_storage__c": "1",
                "Launch_Date__c": "2025-11-15",
                "Current_anticipated_handover_date__c": "2026-10-31",
                "BTS_ANTICIPATED_HANDOVER_DATE__c": "2026-10-31",
                "Handover_Percentage__c": "72",
                "DHRE_Construction_Percent__c": "78",
                "RERA_Construction_Percent__c": "76",
                "RERA_Updated__c": "true",
                "Rera_Inspection_Date__c": "2026-04-15",
                "Disclosure_Statement_Pages_Count__c": "30",
                "Is_Disclosure_Statement_Available__c": "true",
                "Construction_Update_Sent__c": "true",
                "Construction_Updates_Link__c": "https://updates.example.com/damac-lagoons-a",
                "Approved_By_Finance__c": "true",
                "Notes__c": "Damac Lagoons villa inventory seed data.",
                "Description__c": "Full property master data for Damac Lagoons Residences A.",
                "Company__c": "Nakheel",
                "Legal_Entity__c": "Dubai Development Legal Entity",
                "Project_Type__c": "Ready",
                "PropertyCode__c": "PROP-DAM-A",
                "Property_ID_18__c": "003XX0000000003AAA",
                "ERP_Property_Id__c": "ERP-PROP-003",
                "ERP_Property_Code__c": "ERP-PROP-CODE-003",
                "DLD_Property_Id__c": "DLD-PROP-003",
                "Retained_Id__c": "PROP-RET-003",
                "Thw_Property_Code__c": "THW-PROP-003",
                "VAT__r.Retained_Id__c": "VAT-DXB-005",
                "Bank_GL__r.Yardi_GlCode__c": "GL-10001",
                "Default_Bank_Account__r.EBS_Bank_Account_ID__c": "ARBANK-DXB-001",
                "Notes_Receivables_GL__r.Yardi_GlCode__c": "GL-10001",
                "Active__c": "true",
            },
            {
                "Name": "Damac Lagoons Residences B",
                "Unique_External_Key__c": "DAMAC_LAGOONS_DXB_RES_B",
                "Project_Inv__r.Unique_External_Key__c": "DAMAC_LAGOONS_DXB",
                "Property_Name_BF__c": "Damac Lagoons Residences B",
                "Property_Name_BF_SPA__c": "Damac Lagoons Residences B SPA",
                "Property_Name_BF_SPA_AR__c": "داماك لاجونز ريزيدنسز B",
                "Property_Name_Arabic__c": "داماك لاجونز ريزيدنسز B",
                "Property_Name_BF_Ar__c": "داماك لاجونز ريزيدنسز B",
                "Property_Type__c": "Normal",
                "Type_of_Property__c": "Townhouse",
                "Project_Type__c": "Ready",
                "Project_Name_Report__c": "Damac Lagoons",
                "Project_18_Digit_ID__c": "001XX0000000002AAA",
                "Project_Code__c": "DXB-DAM-001",
                "Project_Code_Ar__c": "DXB-DAM-AR-001",
                "Project_Name_in_Arabic__c": "داماك لاجونز",
                "Project_Name__c": "Damac Lagoons",
                "Project_Name_Report__c": "Damac Lagoons",
                "Project__r.Unique_External_Key__c": "DAMAC_LAGOONS_DXB",
                "Building_Name__c": "Damac Lagoons Townhouse Cluster B",
                "Building_Name_Arabic__c": "داماك لاجونز تاون هاوس B",
                "DLD_Area_Name__c": "Dubai Land",
                "Master_Community__c": "Damac Lagoons",
                "Master_Community_Arabic__c": "داماك لاجونز",
                "Terrace__c": "true",
                "Allotted_Parking__c": "2",
                "Alloted_storage__c": "1",
                "Launch_Date__c": "2025-11-15",
                "Current_anticipated_handover_date__c": "2026-10-31",
                "BTS_ANTICIPATED_HANDOVER_DATE__c": "2026-10-31",
                "Handover_Percentage__c": "72",
                "DHRE_Construction_Percent__c": "78",
                "RERA_Construction_Percent__c": "76",
                "RERA_Updated__c": "true",
                "Rera_Inspection_Date__c": "2026-04-15",
                "Disclosure_Statement_Pages_Count__c": "28",
                "Is_Disclosure_Statement_Available__c": "true",
                "Construction_Update_Sent__c": "true",
                "Construction_Updates_Link__c": "https://updates.example.com/damac-lagoons-b",
                "Approved_By_Finance__c": "true",
                "Notes__c": "Damac Lagoons townhouse inventory seed data.",
                "Description__c": "Full property master data for Damac Lagoons Residences B.",
                "Company__c": "Nakheel",
                "Legal_Entity__c": "Dubai Development Legal Entity",
                "Project_Type__c": "Ready",
                "PropertyCode__c": "PROP-DAM-B",
                "Property_ID_18__c": "003XX0000000004AAA",
                "ERP_Property_Id__c": "ERP-PROP-004",
                "ERP_Property_Code__c": "ERP-PROP-CODE-004",
                "DLD_Property_Id__c": "DLD-PROP-004",
                "Retained_Id__c": "PROP-RET-004",
                "Thw_Property_Code__c": "THW-PROP-004",
                "VAT__r.Retained_Id__c": "VAT-DXB-005",
                "Bank_GL__r.Yardi_GlCode__c": "GL-10001",
                "Default_Bank_Account__r.EBS_Bank_Account_ID__c": "ARBANK-DXB-001",
                "Notes_Receivables_GL__r.Yardi_GlCode__c": "GL-10001",
                "Active__c": "true",
            },
        ],
    ),
    ObjectSpec(
        api_name="Unit__c",
        external_key_field="Unique_External_Key__c",
        records=[
            {
                "Name": "SH-A-101",
                "Unique_External_Key__c": "UNIT-SH-A-101",
                "Project__r.Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB",
                "Property__r.Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB_RES_A",
                "Status__c": "Available",
                "Typology__c": "1 BED",
                "Unit_Cost__c": "8500000",
                "Broker_Commission_Percent__c": "2",
            },
            {
                "Name": "SH-A-102",
                "Unique_External_Key__c": "UNIT-SH-A-102",
                "Project__r.Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB",
                "Property__r.Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB_RES_A",
                "Status__c": "Sold",
                "Typology__c": "1 BED + Office",
                "Unit_Cost__c": "8750000",
                "Broker_Commission_Percent__c": "2",
            },
            {
                "Name": "SH-B-201",
                "Unique_External_Key__c": "UNIT-SH-B-201",
                "Project__r.Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB",
                "Property__r.Unique_External_Key__c": "SKYLINE_HEIGHTS_DXB_RES_B",
                "Status__c": "Available",
                "Typology__c": "1 BED + POOL",
                "Unit_Cost__c": "9100000",
                "Broker_Commission_Percent__c": "2",
            },
            {
                "Name": "DL-A-101",
                "Unique_External_Key__c": "UNIT-DL-A-101",
                "Project__r.Unique_External_Key__c": "DAMAC_LAGOONS_DXB",
                "Property__r.Unique_External_Key__c": "DAMAC_LAGOONS_DXB_RES_A",
                "Status__c": "Available",
                "Typology__c": "2 BED",
                "Unit_Cost__c": "10250000",
                "Broker_Commission_Percent__c": "2",
            },
            {
                "Name": "DL-A-102",
                "Unique_External_Key__c": "UNIT-DL-A-102",
                "Project__r.Unique_External_Key__c": "DAMAC_LAGOONS_DXB",
                "Property__r.Unique_External_Key__c": "DAMAC_LAGOONS_DXB_RES_A",
                "Status__c": "Available",
                "Typology__c": "3 BHK + Pool + Maid",
                "Unit_Cost__c": "10750000",
                "Broker_Commission_Percent__c": "2",
            },
            {
                "Name": "DL-B-201",
                "Unique_External_Key__c": "UNIT-DL-B-201",
                "Project__r.Unique_External_Key__c": "DAMAC_LAGOONS_DXB",
                "Property__r.Unique_External_Key__c": "DAMAC_LAGOONS_DXB_RES_B",
                "Status__c": "Available",
                "Typology__c": "1 BED Type A",
                "Unit_Cost__c": "9800000",
                "Broker_Commission_Percent__c": "2",
            },
        ],
    ),
]


def strip_ns(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def parse_field(field_path: Path) -> dict[str, str]:
    root = ET.parse(field_path).getroot()
    data: dict[str, str] = {"type": root.findtext("m:type", default="", namespaces=NS)}
    data["fullName"] = root.findtext("m:fullName", default=field_path.stem.replace(".field-meta", ""), namespaces=NS)
    for child in root:
        key = strip_ns(child.tag)
        if key in {"valueSet", "formula"}:
            continue
        if child.text and key not in data:
            data[key] = child.text.strip()
    ref = root.findtext("m:referenceTo", default="", namespaces=NS)
    if ref:
        data["referenceTo"] = ref
    return data


def collect_fields(object_api: str) -> dict[str, dict[str, str]]:
    fields_dir = OBJECTS_DIR / object_api / "fields"
    fields: dict[str, dict[str, str]] = {}
    if not fields_dir.exists():
        return fields
    for path in sorted(fields_dir.glob("*.field-meta.xml")):
        field = parse_field(path)
        if field.get("formula"):
            continue
        if field.get("type") in {"AutoNumber", "RollUpSummary"}:
            continue
        fields[field["fullName"]] = field
    return fields


def picklist_values(field_path: Path) -> list[str]:
    root = ET.parse(field_path).getroot()
    return [
        value.findtext("m:fullName", default="", namespaces=NS)
        for value in root.findall(".//m:value", NS)
        if value.findtext("m:fullName", default="", namespaces=NS)
    ]


def first_picklist_value(object_api: str, field_name: str) -> str:
    path = OBJECTS_DIR / object_api / "fields" / f"{field_name}.field-meta.xml"
    values = picklist_values(path) if path.exists() else []
    return values[0] if values else ""


def field_value(object_api: str, field_name: str, field_meta: dict[str, str], record: dict[str, str]) -> str:
    if field_name in record:
        return record[field_name]
    if field_name == "Name":
        return record.get("Name", f"{object_api} Seed")

    field_type = field_meta.get("type", "")
    lower_name = field_name.lower()

    if field_type == "Checkbox":
        return "false" if any(token in lower_name for token in ("exclude", "skip", "block", "disable", "inactive", "hidden")) else "true"
    if field_type in {"Number", "Currency", "Percent", "Double", "Integer"}:
        if "price" in lower_name or "amount" in lower_name or "value" in lower_name or "balance" in lower_name:
            return "1000000"
        if "percent" in lower_name or field_type == "Percent":
            return "5"
        if "count" in lower_name or "num" in lower_name or "total" in lower_name:
            return "1"
        return "10"
    if field_type == "Date":
        return "2026-12-31"
    if field_type == "DateTime":
        return "2026-12-31T10:00:00Z"
    if field_type == "Email":
        return f"{object_api.lower().replace('__c', '')}.{field_name.lower()}@dubai-real-estate.example"
    if field_type == "Phone":
        return "+971500000000"
    if field_type == "Url":
        slug = re.sub(r"[^a-z0-9]+", "-", f"{object_api}-{field_name}", flags=re.IGNORECASE).strip("-").lower()
        return f"https://dubai-real-estate.example/{slug}"
    if field_type == "Picklist":
        override = record.get(field_name)
        if override:
            return override
        return first_picklist_value(object_api, field_name)
    if field_type in {"Text", "TextArea", "LongTextArea", "Html"}:
        if "arabic" in lower_name:
            return f"{field_name} دبي"
        if "header" in lower_name:
            return f"Dubai {field_name.replace('_', ' ')}"
        if "description" in lower_name or field_type != "Text":
            return f"Dubai seed value for {object_api}.{field_name}."
        return f"Dubai {field_name.replace('_', ' ')}"
    return record.get(field_name, f"Dubai {object_api} {field_name}")


def output_headers_and_rows(object_api: str, spec: ObjectSpec) -> tuple[list[str], list[list[str]]]:
    fields = collect_fields(object_api)
    headers: list[str] = ["Name"]
    relationship_headers: dict[str, str] = {}

    for field_name, field_meta in fields.items():
        if field_name == "Name":
            continue
        if field_meta.get("referenceTo"):
            ref_object = field_meta["referenceTo"]
            ref_spec = next((s for s in OBJECT_SPECS if s.api_name == ref_object), None)
            if ref_spec and ref_spec.external_key_field:
                header = f"{field_name.replace('__c', '__r')}.{ref_spec.external_key_field}"
                relationship_headers[field_name] = header
                headers.append(header)
            else:
                # Relationship exists but we don't have a seedable external key for the target.
                # Keep the raw field out of the CSV so the file stays importable.
                continue
        else:
            headers.append(field_name)

    rows: list[list[str]] = []
    for record in spec.records:
        row: list[str] = []
        for header in headers:
            if header == "Name":
                row.append(record.get("Name", f"{object_api} Seed"))
                continue
            # Relationship headers map back to the original field name.
            source_field = next((k for k, v in relationship_headers.items() if v == header), None)
            if source_field:
                row.append(record.get(source_field, ""))
                continue
            row.append(field_value(object_api, header, fields.get(header, {}), record))
        rows.append(row)
    return headers, rows


def write_csv(object_api: str, spec: ObjectSpec) -> None:
    headers, rows = output_headers_and_rows(object_api, spec)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path = OUTPUT_DIR / f"{object_api}.csv"
    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(headers)
        writer.writerows(rows)


def main() -> None:
    for spec in OBJECT_SPECS:
        write_csv(spec.api_name, spec)
    readme = OUTPUT_DIR / "README.md"
    readme.write_text(
        "Dubai real estate CSV seed data.\n\n"
        "Import order: VAT__c, AR_GL_Account__c, AR_Legal_Entity__c, AR_Bank_Account__c, Project__c, Property__c, Floor_Plan__c, Unit__c.\n\n"
        "Notes:\n"
        "- CSVs include writable fields discovered from object metadata.\n"
        "- Lookup columns use related-object external keys where the target object exposes one.\n"
        "- `BuildingSection__c` on Unit__c is left blank because the target object is not present in the repo.\n"
        "- `Floor_Plan__c` is seeded, but if your import tool requires an external ID lookup, add one in Salesforce first.\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Archive
Library    RPA.Browser.Playwright
Library    RPA.Dialogs
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Robocorp.Vault
Library    RPA.Tables
Library    OperatingSystem

*** Variables ***
${ORDER_FORM_URL}    https://robotsparebinindustries.com/#/robot-order
${ORDERS_URL}        https://robotsparebinindustries.com/orders.csv
${ORDERS_FILENAME}   ${OUTPUT_DIR}${/}orders.csv
${PDF_DIR}           ${OUTPUT_DIR}${/}receipts${/}
${ZIP_FILENAME}      ${OUTPUT_DIR}${/}receipts.zip

*** Keywords ***
Input orders url dialog
    [Return]    ${ORDERS_URL}
    # Add heading       Process orders from
    # Add text input    url    label=Orders csv file url
    # ${result}=    Run dialog   title=Robot order processor
    # ${url}        Set Variable   ${result.url}
    # Should Not Be Empty          ${url}
    # [Return]  ${url}

Open the robot order website
    # &{secret}=   Get Secret    order_url
    # ${url}=      ${secret.url}
    ${url}=      ${ORDER_FORM_URL}
    New Browser  headless=true
    New Page     ${url}

Get Orders
    [Arguments]          ${url}
    RPA.HTTP.Download    ${url}  ${ORDERS_FILENAME}  overwrite=true
    ${table}             Read table from CSV    ${ORDERS_FILENAME}
    [Return]             ${table}
 
Close the annoying modal
    Click    "OK"

Fill the form    
    [Arguments]  ${row}
    Select Options By    id=head        value    ${row}[Head]
    Check Checkbox       id=id-body-${row}[Body]
    Fill Text            input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Fill Text            id=address     ${row}[Address]

Preview the robot
    Click    id=preview

Submit the order
    Wait Until Keyword Succeeds      5x    0.3s    
    ...    Submit and check if OK
 
Submit and check if OK
    Click          id=order
    Wait For Elements State    id=receipt   visible   timeout=0.2s

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${filename}    Set Variable     ${PDF_DIR}${/}receipt_${order_number}.pdf
    ${receipt}     Get Property     id=receipt     innerHTML
    Log            ${receipt}
    Html To Pdf    ${receipt}       ${filename} 
    [Return]       ${filename}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${filename}    Set Variable  ${PDF_DIR}${/}robot_${order_number}.png
    Take Screenshot  
    ...    ${filename}
    ...    id=robot-preview-image
    [Return]       ${filename}   

Embed the robot screenshot to the receipt PDF file    
    [Arguments]     
    ...    ${screenshot}    
    ...    ${pdf}
    Open Pdf       ${pdf}
    ${files}       Create List      ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}   append=true
    Close Pdf      ${pdf}
    Remove File    ${screenshot}

Go to order another robot
    Click    id=order-another

Create a ZIP file of the receipts
    Archive Folder With ZIP   
    ...    ${PDF_DIR}  
    ...    ${ZIP_FILENAME}   
    ...    include=*.pdf

*** Tasks ***
Order robots from the manufacturer
    ${csv}=       Input orders url dialog
    Open the robot order website
    ${orders}=    Get orders  ${csv}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
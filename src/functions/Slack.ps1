
<#
#>
function Get-PicassioSlackEndpoint
{
    return 'https://slack.com/api'
}

<#
#>
function Send-PicassioSlackMessage
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Channel,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $APIToken,
        
        [string]
        $Colour = $null,
        
        [ValidateNotNullOrEmpty()]
        [string]
        $Username = 'Picassio',
        
        [ValidateNotNullOrEmpty()]
        [string]
        $IconUrl = 'https://cdn.rawgit.com/Badgerati/Picassio2/master/images/icon.png'
    )

    # endpoint
    $endpoint = "$(Get-PicassioSlackEndpoint)/chat.postMessage"

    # remove the hash from the channel name
    $Channel = $Channel.TrimStart('#')

    # contruct the data to post
    $data = "token=$($APIToken)&channel=$($Channel)&link_names=1&as_user=false&username=$($Username)&icon_url=$($IconUrl)"

    if (!(Test-PicassioEmpty $Colour))
    {
        $attachment = "[
            {
                ""fallback"":""$($Message)"",
                ""color"":""$($Colour)"",
                ""text"":""$($Message)""
            }
        ]"

        $data += "&attachments=$($attachment)"
    }
    else
    {
        $data += "&text=$($Message)"
    }

    # send the request
    Write-PicassioInfo "Sending message to Slack"
    Write-PicassioMessage "> Channel: $($Channel)"

    $result = Invoke-PicassioRestEndpoint -Method Post -Uri $endpoint -Body $data -ContentType $null
    if ($result.ok -ne $true)
    {
        if ($result -ne $null)
        {
            throw "Failed to send message to Slack: $($result.error)"
        }
        else
        {
            throw 'Failed to send message to Slack'
        }
    }

    Write-PicassioSuccess "Message sent"
}


<#
#>
function Send-PicassioSlackAttachments
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Channel,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Fallback,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $APIToken,
        
        [string]
        $Pretext = '',
        
        [string]
        $Title = '',
        
        [string]
        $TitleUrl = '',
        
        [string]
        $Text = '',

        [array]
        $Fields = @(),
        
        [ValidateNotNullOrEmpty()]
        [string]
        $Colour = '#439FE0',
        
        [ValidateNotNullOrEmpty()]
        [string]
        $Username = 'Picassio',
        
        [ValidateNotNullOrEmpty()]
        [string]
        $IconUrl = 'https://cdn.rawgit.com/Badgerati/Picassio2/master/images/icon.png'
    )
    
    # endpoint
    $endpoint = "$(Get-PicassioSlackEndpoint)/chat.postMessage"

    # remove the hash from the channel name
    $Channel = $Channel.TrimStart('#')

    # check the titles and URL
    if (!(Test-PicassioEmpty $Title) -and (Test-PicassioEmpty $TitleUrl))
    {
        $TitleUrl = '.'
    }

    if (((Test-PicassioEmpty $Title) -or (Test-PicassioEmpty $TitleUrl)) -and !((Test-PicassioEmpty $Title) -and (Test-PicassioEmpty $TitleUrl)))
    {
        throw "Missing title or title URL for sending Slack attachment message"
    }

    # check that we have either some fields, or text to send
    if ((Test-PicassioEmpty $Text) -and (Test-PicassioEmpty $Fields))
    {
        throw "No text or fields passed to send as an attachment message to Slack"
    }
    
    # contruct the attachment to post
    $fields_data = ''
    if (!(Test-PicassioEmpty $Fields))
    {
        $fields_data = ',"fields": ['

        foreach ($field in $fields)
        {
            $fields_data += "{
                ""title"": ""$(Format-PicassioJsonString $field.title)"",
                ""value"":""$(Format-PicassioJsonString $field.value)"",
                ""short"":$($field.short)
            },"
        }

        $fields_data = $fields_data.TrimEnd(',')
        $fields_data += ']'
    }

    $attachment = "[
        {
            ""fallback"":""$($Fallback)"",
            ""color"":""$($Colour)"",
            ""pretext"":""$($Pretext)"",
            ""title"":""$($Title)"",
            ""title_link"":""$($TitleUrl)"",
            ""text"":""$($Text)""
            $($fields_data)
        }
    ]"

    # contruct the data to post
    $data = "token=$($APIToken)&channel=$($Channel)&link_names=1&as_user=false&username=$($Username)&icon_url=$($IconUrl)&attachments=$($attachment)"

    # send the request
    Write-PicassioInfo "Sending attachment message to Slack"
    Write-PicassioMessage "> Channel: $($Channel)"

    $result = Invoke-PicassioRestEndpoint -Method Post -Uri $endpoint -Body $data -ContentType $null
    if ($result.ok -ne $true)
    {
        if ($result -ne $null)
        {
            throw "Failed to send attachment message to Slack: $($result.error)"
        }
        else
        {
            throw 'Failed to send attachment message to Slack'
        }
    }

    Write-PicassioSuccess "Attachment message sent"
}


<#
#>
function Get-PicassioSlackChannels
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $APIToken
    )
    
    # endpoint
    $endpoint = "$(Get-PicassioSlackEndpoint)/channels.list?token=$($APIToken)&exclude_archived=1"

    # send the request
    Write-PicassioInfo "Retrieving channels from Slack"

    $result = Invoke-PicassioRestEndpoint -Method Get -Uri $endpoint
    if ($result.ok -ne $true)
    {
        if ($result -ne $null)
        {
            throw "Failed to retrieve channels from Slack: $($result.error)"
        }
        else
        {
            throw 'Failed to retrieve channels from Slack'
        }
    }

    return $result.channels.name
}
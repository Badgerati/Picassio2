$path = $MyInvocation.MyCommand.Path
$src = (Split-Path -Parent -Path $path) -ireplace '\\tests\\', '\src\'
$sut = (Split-Path -Leaf -Path $path) -ireplace '\.Tests\.', '.'
. "$($src)\$($sut)"


Describe 'Write-PicassioMessage' {
    Mock Write-Host { }

    Context 'With a message' {
        It 'Should write a message' {
            Write-PicassioMessage -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It
        }

        It 'Should write a message with no new line' {
            Write-PicassioMessage -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-PicassioMessage -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It
        }
    }
}

Describe 'Write-PicassioSuccess' {
    Mock Write-Host { }

    Context 'With a message' {
        It 'Should write a message' {
            Write-PicassioSuccess -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It
        }

        It 'Should write a message with no new line' {
            Write-PicassioSuccess -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-PicassioSuccess -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It
        }
    }
}

Describe 'Write-PicassioError' {
    Mock Write-Host { }

    Context 'With a message' {
        It 'Should write a message' {
            Write-PicassioError -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It
        }

        It 'Should write a message with no new line' {
            Write-PicassioError -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It
        }

        It 'Should throw the message as an error when told' {
            { Write-PicassioError -Message 'Error' -ThrowError } | Should Throw 'Error'
            Assert-MockCalled Write-Host -Times 1 -Scope It
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-PicassioError -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It
        }
    }
}

Describe 'Write-PicassioWarning' {
    Mock Write-Host { }

    Context 'With a message' {
        It 'Should write a message' {
            Write-PicassioWarning -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It
        }

        It 'Should write a message with no new line' {
            Write-PicassioWarning -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-PicassioWarning -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It
        }
    }
}

Describe 'Write-PicassioInfo' {
    Mock Write-Host { }

    Context 'With a message' {
        It 'Should write a message' {
            Write-PicassioInfo -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It
        }

        It 'Should write a message with no new line' {
            Write-PicassioInfo -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-PicassioInfo -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It
        }
    }
}

Describe 'Write-PicassioException' {
    Mock Write-PicassioError { }

    Context 'With an exception' {
        It 'Should display the type and message' {
            Write-PicassioException -Exception (New-Object System.Exception -ArgumentList 'error')
            Assert-MockCalled Write-PicassioError -Times 2 -Scope It
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-PicassioException -Exception $null } | Should Throw 'The argument is null'
            Assert-MockCalled Write-PicassioError -Times 0 -Scope It
        }
    }
}

Describe 'Write-PicassioHeader' {
    Mock Write-Host { }

    Context 'With a message' {
        It 'Should write a message' {
            Write-PicassioHeader -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-PicassioHeader -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It
        }
    }
}

Describe 'Write-PicassioSubHeader' {
    Mock Write-Host { }

    Context 'With a message' {
        It 'Should write a message' {
            Write-PicassioSubHeader -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-PicassioSubHeader -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It
        }
    }
}
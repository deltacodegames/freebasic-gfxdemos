'#################################################
'# 
'# Official site: www.JatteGames.com
'# 
'# Code posted by Jattenalle is Copyright(c) 2026- Johannes "Jattenalle" Pihl,
'#     all rights reserved
'# 
'#     This software is provided 'as-is', without any express or implied
'#     warranty. In no event will the authors be held liable for any damages
'#     arising from the use of this software.
'#     
'#     Permission is granted to anyone to use this software for any purpose,
'#     including commercial applications, and to alter it and redistribute it
'#     freely, subject to the following restrictions:
'#     
'#     1. The origin of this software must not be misrepresented; you must not
'#        claim that you wrote the original software. If you use this software
'#        in a product, an acknowledgment in the product documentation would be
'#        appreciated but is not required.
'#     2. Altered source versions must be plainly marked as such, and must not be
'#        misrepresented as being the original software.
'#     3. This notice may not be removed or altered from any source distribution.
'# 
'#################################################
'// Make sure we use the latest Windows headers FB supports
#undef _WIN32_WINNT
#define _WIN32_WINNT &h0602
#include once "windows.bi"

dim shared as boolean isDPIAware = FALSE

sub EnableDPIAwareness()
    dim shcoredll as any ptr
    shcoredll=dylibload("shcore")
    if shcoredll then
        dim SetProcessDpiAwareness as function stdcall(byval PROCESS_DPI_AWARENESS as long) as long
        SetProcessDpiAwareness=DyLibSymbol(shcoredll,"SetProcessDpiAwareness")
        if SetProcessDpiAwareness then '// Win8.1+
            dim as long ret1=SetProcessDpiAwareness(2)
            if ret1 then
                print "DPI: SetProcessDPIAwareness() returned ERR ["& ret1 &"]"
            else
                isDPIAware = TRUE
                print "DPI: SetProcessDPIAwareness() returned S_OK ["& ret1 &"]"
            end if
        else
            print "DPI : SetProcessDPIAwareness not found."
        end if
    else
        print "DPI: SHCORE is not available"
    end if
    if isDPIAware = FALSE then
        dim as boolean ret = SetProcessDPIAware()'// WinVista to Win8
        if ret then
            isDPIAware = TRUE
            print "DPI: SetProcessDPIAware() returned S_OK ["& ret &"]"
        else
            print "DPI: SetProcessDPIAware() returned ERR ["& ret &"]"
        end if
    end if
end sub

EnableDPIAwareness() '// Must be done BEFORE *any* graphics related calls

if isDPIAware then
    print "DPI awareness is ENABLED"
else
    print "DPI awareness is not enabled"
end if

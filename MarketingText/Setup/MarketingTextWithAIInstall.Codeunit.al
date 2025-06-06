// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Techdays.AITestToolkitDemo;
using System.Environment;
using System.AI;

codeunit 50101 "Marketing Text With AI Install"
{
    Subtype = Install;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapability();
    end;

    local procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        LearnMoreUrlTxt: Label 'https://microsoft.com', Locked = true;
    begin
        // Register capability
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Marketing Text Simple") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Marketing Text Simple", Enum::"Copilot Availability"::Preview, LearnMoreUrlTxt);
    end;
}
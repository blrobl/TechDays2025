// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Techdays.AITestToolkitDemo;
using Microsoft.Inventory.Item;
using System.AI;

codeunit 50100 "Marketing Text With AI"
{
    Access = Internal;

    procedure GenerateTagLine(ItemNo: Code[20]; MaxLength: Integer): Text
    var
        Item: Record Item;
        TagLine: Text;
        UserPrompt: Text;
    begin
        // Generate the tag line using AI
        Item.Get(ItemNo);

        UserPrompt := 'Generate *only* the tagline for the item ' + Item.Description
                        + ' with unit of measure ' + Item."Base Unit of Measure"
                        + '. *The maximum length of the tagline should be ' + Format(MaxLength) + ' characters*.';

        TagLine := this.GenerateCompletion(UserPrompt, GeneratedTextOption::Tagline);

        exit(TagLine);
    end;

    procedure GenerateMarketingText(ItemNo: Code[20]; Style: Enum "Marketing Text Style"): Text
    var
        Item: Record Item;
        UserPrompt: Text;
    begin
        // Generate the marketing text using AI
        Item.Get(ItemNo);

        UserPrompt := 'Generate the marketing text paragraph (within 200 words) for the item ' + Item.Description
                        + ' with unit of measure ' + Item."Base Unit of Measure"
                        + '. The style should be ' + Format(Style);

        exit(this.GenerateCompletion(UserPrompt, GeneratedTextOption::Content));
    end;

    local procedure GenerateCompletion(UserPrompt: Text; TextOption: Option Tagline,Content): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        GenerateTextFunctionCalling: Codeunit "Generate Text Function Calling";
    begin
        // Setup Azure OpenAI
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Marketing Text Simple");
        SetAuthorization(AzureOpenAI);

        // Add functions
        GenerateTextFunctionCalling.SetOption(TextOption);
        AOAIChatMessages.AddTool(GenerateTextFunctionCalling);
        AOAIChatMessages.SetToolChoice('auto');

        AOAIChatMessages.SetPrimarySystemMessage(this.GetSystemPrompt());
        AOAIChatMessages.AddUserMessage(UserPrompt);

        // Start Order Copilot
        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIOperationResponse);

        if AOAIOperationResponse.IsSuccess() then begin
            if AOAIOperationResponse.IsFunctionCall() then begin
                AOAIFunctionResponse := AOAIOperationResponse.GetFunctionResponse();
                if AOAIFunctionResponse.IsSuccess() then
                    exit(AOAIFunctionResponse.GetResult())
                else
                    Error(AOAIFunctionResponse.GetError());
            end;
        end else
            Error(AOAIOperationResponse.GetError());
    end;

    local procedure GetSystemPrompt(): SecretText
    var
        SystemPromptLbl: Label 'You can generate marketing text and tagline for the marketing text. Generate them based on the user''s instructions.', Locked = true;
    begin
        exit(Format(SystemPromptLbl));
    end;

    local procedure GetSystemPromptResource(): SecretText
    begin
        // TODO resource policies
        exit(NavApp.GetResourceAsText('prompt.txt'));
    end;

    local procedure GetSystemPromptKeyVault(): SecretText
    var
        SecretProvider: Codeunit System.Security."App Key Vault Secret Provider";
        SystemPrompt: SecretText;
    begin
        if SecretProvider.TryInitializeFromCurrentApp() then
            SecretProvider.GetSecret('SystemPrompt', SystemPrompt);

        exit(SystemPrompt);
    end;

    local procedure SetAuthorization(var AzureOpenAI: Codeunit "Azure OpenAI")
    var
        SecretProvider: Codeunit System.Security."App Key Vault Secret Provider";

        Endpoint: Text;
        Deployment: Text;
        Apikey: SecretText;
    begin
        IsolatedStorage.Get('Endpoint', Endpoint);
        IsolatedStorage.Get('Deployment', Deployment);

        if SecretProvider.TryInitializeFromCurrentApp() then
            SecretProvider.GetSecret('CopilotApiKey', ApiKey)
        else
            IsolatedStorage.Get('Apikey', Apikey);

        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", Endpoint, Deployment, Apikey);
    end;

    var
        GeneratedTextOption: Option Tagline,Content;
}
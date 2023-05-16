local services = {
    http = game:GetService('HttpService')
}

local http = (syn and syn.request) or request or http_request

client = {
    allowed_models = {
        text_completion = {
            'text-davinci-003'
        },
        chat_completion = {
            'text-davinci-003',
            'gpt-3.5-turbo',
            'alpaca-13b',
            'vicuna-13b',
            'koala-13b',
            'llama-13b',
            'oasst-pythia-12b',
            'fastchat-t5-3b',
            'gpt-4'
        }
    },
    options = {
        api_key = nil,
        api_base = nil
    },
    functions = {
        TextCompletion = function(args)
            local prompt = args.prompt
            local temperature = args.temperature or 0.7
            local max_tokens = args.max_tokens or 256
            local stop = args.stop or {}

            if prompt == nil then
                error('OpenLib Error: No prompt provided, please provide a prompt as a string')
                return
            elseif type(prompt) ~= 'string' then
                error('OpenLib Error: Make sure that your prompt is a string')
                return
            end

            if max_tokens >= 2049 then
                error('OpenLib Error: Text completion (text-davinci-003) only supports up to 2048 tokens, please lower your max token limit, keep in mind that the prompt counts twoards the token limit too!')
                return
            end

            if temperature > 1 then
                error('OpenLib Error: Temperature can only be in a range of 0 to 1, please make sure that you are in that range!')
                return
            elseif temperature < 0 then
                error('OpenLib Error: Temperature can only be in a range of 0 to 1, please make sure that you are in that range!')
                return
            end

            local res = http({
                Url = string.format('%s/completions', client.options.api_base),
                Method = 'POST',
                Headers = {
                    ['Authorization'] = 'Bearer '..client.options.api_key,
                    ['Content-Type'] = 'application/json'
                },
                Body = services.http:JSONEncode({
                    ['model'] = 'text-davinci-003',
                    ['prompt'] = prompt,
                    ['temperature'] = temperature,
                    ['max_tokens'] = max_tokens,
                    ['stop'] = stop
                })
            })

            if res.Success then
                local resBody = services.http:JSONDecode(res.Body)

                local toReturn = {
                    model = resBody['model'],
                    choice = resBody['choices'][1],
                    usage = resBody['usage']
                }

                return toReturn
            else
                error('OpenLib Error: API Error:\n'..res.Body)
            end
        end,
        ChatCompletion = function(args)
            local model = args.model or 'gpt-3.5-turbo'
            local messages = args.messages
            local max_tokens = args.max_tokens or 256

            if messages == nil then
                error('OpenLib Error: No messages provided, please provide messages as a table')
                return
            elseif type(messages) ~= 'table' then
                error('OpenLib Error: Make sure that your messages are a dictionary')
                return
            end

            if max_tokens >= 4097 then
                error('OpenLib Error: Chat completion (text-davinci-003 or gpt-3.5-turbo) only supports up to 4097 tokens, please lower your max token limit, keep in mind that the prompt counts twoards the token limit too!')
                return
            end

            local supportedModel = false

            for _,v in next, client.allowed_models.chat_completion do
                if model == v then
                    supportedModel = true
                    break
                end
            end

            if not supportedModel then
                error('OpenLib Error: Chat Completion doesnt support the "' .. model .. '" model. Please check the documentation for what models are available on chat completion: https://dosware.net/openlib')
            end


            for _,v in next, messages do
                if not v.role and not v.content then
                    error('OpenLib Error: Chat Completion (text-davinci-003 or gpt-3.5-turbo) messages must be a table with tables that have the following properties in them: role, content, check the documentation for more details: https://dosware.net/openlib')
                end
            end

            local res = http({
                Url = string.format('%s/chat/completions', client.options.api_base),
                Method = 'POST',
                Headers = {
                    ['Authorization'] = 'Bearer '..client.options.api_key,
                    ['Content-Type'] = 'application/json'
                },
                Body = services.http:JSONEncode({
                    ['model'] = model,
                    ['max_tokens'] = max_tokens,
                    ['messages'] = messages,
                })
            })

            if res.Success then
                local resBody = services.http:JSONDecode(res.Body)

                local toReturn = {
                    model = resBody['model'],
                    choice = resBody['choices'][1],
                    choice_message = resBody['choices'][1]['message'],
                    usage = resBody['usage']
                }

                return toReturn
            else
                error('OpenLib Error: API Error:\n\n'..res.Body..'\n\n')
            end
        end
    }
}

OpenLib = {
    init = function(args)
        local reset_ip = args.reset_ip or true
        local api_key = args.api_key
        local api_base = args.api_base or 'https://api.pawan.krd/v1'

        if api_key == nil then
            error('OpenLib Error: No api key provided, please provide an api key in this format as a string: pk-***********************')
            return
        elseif type(api_key) ~= 'string' then
            error('OpenLib Error: Api key must be a string, please provide an api key in this format as a string: pk-***********************')
            return
        elseif type(api_key) == 'string' then
            client.options.api_key = api_key
            if type(api_base) ~= 'nil' and type(api_base) ~= 'string' then
                error('OpenLib Error: api_base has to be a string or left as default, please check the api_base variable and the OpenLib docs: https://dosware.net/openlib')
                return
            else
                if reset_ip == true and api_base == 'https://api.pawan.krd/v1' then
                    http({
                        Url = 'https://api.pawan.krd/resetip',
                        Method = 'POST',
                        Headers = {
                            ['Authorization'] = 'Bearer '..api_key
                        }
                    })
                end

                client.options.api_base = api_base
                return client.functions
            end
        else
            error('OpenLib Error: Unkown error, please check the docs and make sure that you initialized OpenLib correctly: https://dosware.net/openlib')
        end
    end
}

return OpenLib

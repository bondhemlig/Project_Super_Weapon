-- Super Weapon Controller
-- Keplaris
-- January 29, 2023



local SuperWeaponController = {
    state = "Charging"
}

function SuperWeaponController:Start()
	self.State = self.state
    local UIS = game:GetService("UserInputService")
    local SuperWeaponService = self.Services.GunnerService


    local function start(seat, power)
        print("Start")
        local userInput = require(script.Parent.UserInput)
        local keyboard = userInput:Get("Keyboard")
        
        self.inputListener = keyboard.KeyDown:Connect(function(key) 
        print(key)    
        if self.state == "Firing" then 
            print("Return")
            return    
        elseif key == Enum.KeyCode.F then
                print("GO!", power.Value)
                if power.Value > 0 then
                    print("Fire Server")
                    SuperWeaponService.Fire:Fire(seat, power.Value)
                    self.state = "Firing"
                
                    local tween = game:GetService("TweenService"):Create(power, TweenInfo.new(
                        2,
                        Enum.EasingStyle.Quad,
                        Enum.EasingDirection.In
                    ), 
                    {
                        Value = 0    
                })

                tween:Play()
                tween.Completed:Wait()
                self.state = "Charging"    
            end
            elseif key == Enum.KeyCode.Q then
                while UIS:IsKeyDown(Enum.KeyCode.Q) and self.state == "Charging" do
                    task.wait()
                    print("Charging up")
                    power.Value = math.clamp(power.Value + 0.005, 0, 1)
                end
            elseif key == Enum.KeyCode.E then
                while UIS:IsKeyDown(Enum.KeyCode.E) and self.state == "Charging" do
                    task.wait()
                    print("Reducing power")
                    power.Value = math.clamp(power.Value - 0.04, 0, 1)
                end
            end

        end)
        return userInput
    end

    print(self.Services)
    SuperWeaponService.Activate:Connect(function(seat)
        start(seat, seat:FindFirstChildOfClass("NumberValue"))
    end)

    SuperWeaponService.Deactivate:Connect(function()
        if self.inputListener then
            self.inputListener:Disconnect()
        end
    end)

   -- Fire the signal:
end


function SuperWeaponController:Init()

end


return SuperWeaponController
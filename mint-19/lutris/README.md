WIP

Installs Lutris

What works:

1. Script expects you to have wine staging installed already. This can be done easily using my wine-staging setup script.
2. If you have an NVIDIA card, script expects you to have installed proprietary drivers AND Vulkan. It will prompt you.
3. Assuming you meet the requirements for 1 and 2, then script should add Lutris PPA if you don't have it
4. Assuming you meet the requirements for 1 and 2, then script should install Lutris package

What needs work/verification:

1. Need to test on non-nvidia box; should work as long as wine-staging is already installed but need to confirm

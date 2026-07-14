#include <imgui/imgui.h>
#include <imgui/imgui_impl_glfw.h>
#include <imgui/imgui_impl_opengl3.h>
#include <stdio.h>

int main(void) {
    printf("imgui %s\n", IMGUI_VERSION);

    ImGui::CreateContext();
    ImGui::StyleColorsDark();

    // Reference the backend entry points so they are pulled in from the
    // static archive and verified to link (no GL context needed here).
    (void)&ImGui_ImplGlfw_InitForOpenGL;
    (void)&ImGui_ImplOpenGL3_Init;

    ImGui::DestroyContext();
    printf("OK\n");
    return 0;
}

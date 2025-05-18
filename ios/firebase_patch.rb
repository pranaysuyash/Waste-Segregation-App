# Monkey patch to fix FirebaseCore dependency issues
module Pod
  class Installer
    class Analyzer
      class SandboxAnalyzer
        alias_method :orig_pod_state_for_podfile_state, :pod_state_for_podfile_state
        
        def pod_state_for_podfile_state(pod_name, requirements)
          if pod_name.start_with?('Firebase') || pod_name.start_with?('Google')
            return Pod::Installer::Analyzer::SpecsState::CHANGED
          end
          orig_pod_state_for_podfile_state(pod_name, requirements)
        end
      end
    end
  end
end

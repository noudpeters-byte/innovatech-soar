# Patches every SOAR node the same way: no SSH, no per-machine work (P1-05)
resource "aws_ssm_association" "patch_soar_nodes" {
  name                = "AWS-RunPatchBaseline"
  association_name    = "soar-weekly-patch"
  schedule_expression = "rate(7 days)"

   parameters = {
    Operation    = "Install"
    RebootOption = "NoReboot"
  }

  targets {
    key    = "tag:Name"
    values = ["soar-node"]
  }

  
}
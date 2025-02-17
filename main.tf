
resource null_resource wait_for_sync {
  provisioner "local-exec" {
    command = "echo 'Sync: ${var.sync != null ? var.sync : ""}'"
  }
}

module "clis" {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

resource "random_uuid" "tag" {
}

resource null_resource resource_group {
  depends_on = [null_resource.wait_for_sync, module.clis]

  triggers = {
    IBMCLOUD_API_KEY = base64encode(var.ibmcloud_api_key)
    RESOURCE_GROUP_NAME  = var.resource_group_name
    AUTOMATION_TAG  = "automation:${random_uuid.tag.result}"
    BIN_DIR = module.clis.bin_dir
  }

  provisioner "local-exec" {
    when        = create
    command = "${path.module}/scripts/create-resource-group.sh"
    environment = {
      IBMCLOUD_API_KEY = base64decode(self.triggers.IBMCLOUD_API_KEY)
      RESOURCE_GROUP_NAME  = self.triggers.RESOURCE_GROUP_NAME
      AUTOMATION_TAG  = self.triggers.AUTOMATION_TAG
      BIN_DIR = self.triggers.BIN_DIR
    }
  }

  provisioner "local-exec" {
    when        = destroy
    command = "${path.module}/scripts/delete-resource-group.sh"
    environment = {
      IBMCLOUD_API_KEY = base64decode(self.triggers.IBMCLOUD_API_KEY)
      RESOURCE_GROUP_NAME  = self.triggers.RESOURCE_GROUP_NAME
      AUTOMATION_TAG  = self.triggers.AUTOMATION_TAG
      BIN_DIR = self.triggers.BIN_DIR
    }
  }
}



data ibm_resource_group resource_group {
  depends_on = [null_resource.wait_for_sync, null_resource.resource_group]

  name  = var.resource_group_name
}

<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/reopt/reopt_schema/reopt_schema.json";
export default {
  name: "ReoptSchema",
  data() {
    return { schema };
  }
};
</script>
<template>
  <JsonSchema :schema="schema"/>
</template>
<script>
import { default as schema } from "../../../lib/urbanopt/reopt/reopt_schema/reopt_output_schema.json";
export default {
  name: "ReoptOutputSchema",
  data() {
    return { schema };
  }
};
</script>
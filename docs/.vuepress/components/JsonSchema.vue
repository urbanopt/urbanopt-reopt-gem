<template>
  <ClientOnly>
    <InnerJsonSchema :schema="schema" />
  </ClientOnly>
</template>

<script>
export default {
  name: 'JsonSchema',
  props: ['schema'],
}
</script>

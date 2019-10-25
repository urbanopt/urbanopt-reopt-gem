<script>
export default {
  name: "StaticLink",
  render(h) {
    return h("a", { domProps: this.props }, this.$slots.default);
  }
};
</script>
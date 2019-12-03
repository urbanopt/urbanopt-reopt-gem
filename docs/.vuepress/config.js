module.exports = {
  base: '/urbanopt-reopt-gem/',
  themeConfig: {
    navbar: false,
   sidebar: [
     "/",
     {
       title: "Schemas",
       children: [
          "/schemas/reopt-input-schema.md",
          "/schemas/reopt-output-schema.md"
       ]
     }
   ]
  }
};
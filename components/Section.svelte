<script>
    export let type = 'default'; // 'question' | 'background' | 'investigation' | 'takeaways' | 'default'
</script>

<div class="section-wrapper" data-section-type={type}>
    <div class="section-inner">
        <slot />
    </div>
</div>

<style>
    /* Unified section system - consistent structure, distinct accents */
    .section-wrapper {
        position: relative;
        margin: 2.5rem 0;
        padding-left: 1.5rem;
        border-left: 3px solid var(--color-base-300, #ddd);
    }

    .section-inner {
        padding: 0.5rem 0;
    }

    @media (max-width: 640px) {
        .section-wrapper {
            padding-left: 0.625rem;
            margin: 1.75rem 0;
            border-left-width: 2px;
        }

        .section-wrapper[data-section-type="question"],
        .section-wrapper[data-section-type="takeaways"] {
            border-left-width: 3px;
        }

        .section-inner {
            padding: 0.25rem 0;
        }

        .section-wrapper :global(h2.markdown:first-child) {
            font-size: 0.75rem;
            margin-bottom: 1rem;
        }

        .section-wrapper[data-section-type="question"] :global(p.markdown) {
            font-size: 1.125rem;
            line-height: 1.55;
        }

        .section-wrapper[data-section-type="background"] :global(p.markdown) {
            font-size: 1rem;
            line-height: 1.65;
        }

        .section-wrapper[data-section-type="investigation"] :global(h3.markdown) {
            font-size: 1.0625rem;
            margin-top: 1.5rem;
            margin-bottom: 0.625rem;
        }

        .section-wrapper[data-section-type="takeaways"] :global(li.markdown) {
            padding-left: 1.25rem;
            margin-bottom: 0.5rem;
            font-size: 1rem;
            line-height: 1.55;
        }
    }

    /* Shared heading styles */
    .section-wrapper :global(h2.markdown:first-child) {
        font-size: 0.6875rem;
        font-weight: 700;
        letter-spacing: 0.1em;
        text-transform: uppercase;
        margin-top: 0;
        margin-bottom: 1.25rem;
        padding-bottom: 0;
        border-bottom: none;
    }

    /* Question Section - Blue accent, larger question text */
    .section-wrapper[data-section-type="question"] {
        border-left-color: #3b82f6;
        border-left-width: 4px;
    }

    .section-wrapper[data-section-type="question"] :global(h2.markdown:first-child) {
        color: #3b82f6;
    }

    .section-wrapper[data-section-type="question"] :global(p.markdown) {
        font-size: 1.25rem;
        font-weight: 500;
        line-height: 1.5;
        letter-spacing: -0.01em;
        color: var(--color-base-content, #1a1a1a);
        margin: 0;
    }

    /* Background Section - Muted accent */
    .section-wrapper[data-section-type="background"] {
        border-left-color: var(--color-base-300, #ccc);
    }

    .section-wrapper[data-section-type="background"] :global(h2.markdown:first-child) {
        color: var(--color-base-content-muted, #666);
    }

    .section-wrapper[data-section-type="background"] :global(p.markdown) {
        color: var(--color-base-content-muted, #555);
        font-size: 0.9375rem;
        line-height: 1.7;
    }

    .section-wrapper[data-section-type="background"] :global(strong.markdown) {
        color: var(--color-base-content, #333);
        font-weight: 600;
    }

    /* Investigation Section - Neutral accent */
    .section-wrapper[data-section-type="investigation"] {
        border-left-color: #6b7280;
    }

    .section-wrapper[data-section-type="investigation"] :global(h2.markdown:first-child) {
        color: #6b7280;
    }

    .section-wrapper[data-section-type="investigation"] :global(h3.markdown) {
        font-size: 1.125rem;
        font-weight: 600;
        margin-top: 2rem;
        margin-bottom: 0.75rem;
        color: var(--color-base-content, #1a1a1a);
    }

    .section-wrapper[data-section-type="investigation"] :global(h3.markdown:first-of-type) {
        margin-top: 0;
    }

    /* Takeaways Section - Green accent */
    .section-wrapper[data-section-type="takeaways"] {
        border-left-color: #10b981;
        border-left-width: 4px;
    }

    .section-wrapper[data-section-type="takeaways"] :global(h2.markdown:first-child) {
        color: #10b981;
    }

    .section-wrapper[data-section-type="takeaways"] :global(ul.markdown),
    .section-wrapper[data-section-type="takeaways"] :global(ol.markdown) {
        padding-left: 0;
        list-style: none;
    }

    .section-wrapper[data-section-type="takeaways"] :global(li.markdown) {
        position: relative;
        padding-left: 1.5rem;
        margin-bottom: 0.625rem;
        line-height: 1.6;
    }

    .section-wrapper[data-section-type="takeaways"] :global(li.markdown::before) {
        content: "→";
        position: absolute;
        left: 0;
        color: #10b981;
        font-weight: 600;
    }

    /* Default Section */
    .section-wrapper[data-section-type="default"] :global(h2.markdown:first-child) {
        color: var(--color-base-content-muted, #666);
    }
</style>
